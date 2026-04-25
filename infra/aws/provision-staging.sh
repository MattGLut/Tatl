#!/usr/bin/env bash
# Provision the Tatl staging environment in AWS us-east-2.
#
# Prerequisites:
#   - AWS CLI v2 installed and configured (`aws configure` with us-east-2)
#   - Default VPC exists in us-east-2 (AWS creates one automatically)
#
# Usage:
#   chmod +x infra/aws/provision-staging.sh
#   ./infra/aws/provision-staging.sh
#
# The script is idempotent where possible (checks for existing resources).
# After completion it prints the values you need for GitHub Secrets and
# the EC2 setup script.

set -euo pipefail

REGION="us-east-2"
PROJECT="tatl"
ENV_NAME="staging"
PREFIX="${PROJECT}-${ENV_NAME}"

EC2_INSTANCE_TYPE="t3.small"
RDS_INSTANCE_CLASS="db.t4g.micro"
RDS_ENGINE_VERSION="16"
RDS_DB_NAME="tatl_staging"
RDS_MASTER_USER="tatl"
S3_BUCKET="${PREFIX}-uploads"
KEY_NAME="${PREFIX}"
KEY_FILE="$HOME/.ssh/${KEY_NAME}.pem"

echo "=== Tatl staging provisioner (${REGION}) ==="

# ── Discover default VPC ─────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=is-default,Values=true" \
  --query "Vpcs[0].VpcId" --output text --region "$REGION")

if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
  echo "ERROR: No default VPC found in ${REGION}. Create one first:"
  echo "  aws ec2 create-default-vpc --region ${REGION}"
  exit 1
fi
echo "Default VPC: ${VPC_ID}"

# ── Get subnets (need ≥2 AZs for RDS subnet group) ──────────────────
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query "Subnets[*].SubnetId" --output text --region "$REGION")
echo "Subnets: ${SUBNET_IDS}"

# ── Key pair ─────────────────────────────────────────────────────────
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
  echo "Key pair '${KEY_NAME}' already exists"
else
  echo "Creating key pair '${KEY_NAME}' → ${KEY_FILE}"
  aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --key-type ed25519 \
    --query "KeyMaterial" --output text \
    --region "$REGION" > "$KEY_FILE"
  chmod 400 "$KEY_FILE"
fi

# ── Security group: web (SSH + HTTP) ────────────────────────────────
WEB_SG_NAME="${PREFIX}-web"
WEB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${WEB_SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
  --query "SecurityGroups[0].GroupId" --output text --region "$REGION" 2>/dev/null || echo "None")

if [[ "$WEB_SG_ID" == "None" || -z "$WEB_SG_ID" ]]; then
  echo "Creating security group '${WEB_SG_NAME}'"
  WEB_SG_ID=$(aws ec2 create-security-group \
    --group-name "$WEB_SG_NAME" \
    --description "Tatl staging - SSH + HTTP" \
    --vpc-id "$VPC_ID" \
    --query "GroupId" --output text --region "$REGION")

  aws ec2 authorize-security-group-ingress --group-id "$WEB_SG_ID" --region "$REGION" \
    --ip-permissions \
      "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0,Description=SSH}]" \
      "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0,Description=HTTP}]" \
      "IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0,Description=HTTPS}]"
fi
echo "Web SG: ${WEB_SG_ID}"

# ── Security group: RDS (Postgres from web SG only) ─────────────────
RDS_SG_NAME="${PREFIX}-rds"
RDS_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${RDS_SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
  --query "SecurityGroups[0].GroupId" --output text --region "$REGION" 2>/dev/null || echo "None")

if [[ "$RDS_SG_ID" == "None" || -z "$RDS_SG_ID" ]]; then
  echo "Creating security group '${RDS_SG_NAME}'"
  RDS_SG_ID=$(aws ec2 create-security-group \
    --group-name "$RDS_SG_NAME" \
    --description "Tatl staging RDS - Postgres from web SG" \
    --vpc-id "$VPC_ID" \
    --query "GroupId" --output text --region "$REGION")

  aws ec2 authorize-security-group-ingress --group-id "$RDS_SG_ID" --region "$REGION" \
    --ip-permissions \
      "IpProtocol=tcp,FromPort=5432,ToPort=5432,UserIdGroupPairs=[{GroupId=${WEB_SG_ID},Description=Postgres-from-web}]"
fi
echo "RDS SG: ${RDS_SG_ID}"

# ── EC2 instance ─────────────────────────────────────────────────────
EXISTING_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${PREFIX}" "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[0].Instances[0].InstanceId" --output text --region "$REGION" 2>/dev/null || echo "None")

if [[ "$EXISTING_INSTANCE" != "None" && -n "$EXISTING_INSTANCE" ]]; then
  INSTANCE_ID="$EXISTING_INSTANCE"
  echo "EC2 instance already exists: ${INSTANCE_ID}"
else
  # Ubuntu 24.04 LTS AMD64 - canonical owner 099720109477
  AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
              "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text --region "$REGION")

  echo "Launching EC2 ${EC2_INSTANCE_TYPE} with AMI ${AMI_ID}"
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$EC2_INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$WEB_SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PREFIX}}]" \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=20,VolumeType=gp3}" \
    --query "Instances[0].InstanceId" --output text --region "$REGION")

  echo "Waiting for instance ${INSTANCE_ID} to be running..."
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
fi
echo "EC2 Instance: ${INSTANCE_ID}"

# ── Elastic IP ───────────────────────────────────────────────────────
EIP_ALLOC=$(aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=${PREFIX}" \
  --query "Addresses[0].AllocationId" --output text --region "$REGION" 2>/dev/null || echo "None")

if [[ "$EIP_ALLOC" == "None" || -z "$EIP_ALLOC" ]]; then
  echo "Allocating Elastic IP"
  EIP_ALLOC=$(aws ec2 allocate-address \
    --domain vpc \
    --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${PREFIX}}]" \
    --query "AllocationId" --output text --region "$REGION")
fi

CURRENT_ASSOC=$(aws ec2 describe-addresses \
  --allocation-ids "$EIP_ALLOC" \
  --query "Addresses[0].AssociationId" --output text --region "$REGION" 2>/dev/null || echo "None")

if [[ "$CURRENT_ASSOC" == "None" || -z "$CURRENT_ASSOC" ]]; then
  aws ec2 associate-address \
    --instance-id "$INSTANCE_ID" \
    --allocation-id "$EIP_ALLOC" \
    --region "$REGION" > /dev/null
fi

EIP_PUBLIC=$(aws ec2 describe-addresses \
  --allocation-ids "$EIP_ALLOC" \
  --query "Addresses[0].PublicIp" --output text --region "$REGION")
echo "Elastic IP: ${EIP_PUBLIC}"

# ── RDS subnet group ────────────────────────────────────────────────
RDS_SUBNET_GROUP="${PREFIX}-db"
if ! aws rds describe-db-subnet-groups --db-subnet-group-name "$RDS_SUBNET_GROUP" --region "$REGION" &>/dev/null; then
  echo "Creating RDS subnet group '${RDS_SUBNET_GROUP}'"
  aws rds create-db-subnet-group \
    --db-subnet-group-name "$RDS_SUBNET_GROUP" \
    --db-subnet-group-description "Tatl staging RDS subnets" \
    --subnet-ids $SUBNET_IDS \
    --region "$REGION" > /dev/null
fi

# ── RDS instance ─────────────────────────────────────────────────────
RDS_IDENTIFIER="${PREFIX}-db"
RDS_STATUS=$(aws rds describe-db-instances \
  --db-instance-identifier "$RDS_IDENTIFIER" \
  --query "DBInstances[0].DBInstanceStatus" --output text --region "$REGION" 2>/dev/null || echo "not-found")

if [[ "$RDS_STATUS" == "not-found" ]]; then
  echo ""
  echo "About to create RDS instance. You need a master password."
  read -rsp "Enter RDS master password for user '${RDS_MASTER_USER}': " RDS_PASSWORD
  echo ""

  echo "Creating RDS ${RDS_INSTANCE_CLASS} PostgreSQL ${RDS_ENGINE_VERSION}"
  aws rds create-db-instance \
    --db-instance-identifier "$RDS_IDENTIFIER" \
    --db-instance-class "$RDS_INSTANCE_CLASS" \
    --engine postgres \
    --engine-version "$RDS_ENGINE_VERSION" \
    --master-username "$RDS_MASTER_USER" \
    --master-user-password "$RDS_PASSWORD" \
    --db-name "$RDS_DB_NAME" \
    --allocated-storage 20 \
    --storage-type gp3 \
    --vpc-security-group-ids "$RDS_SG_ID" \
    --db-subnet-group-name "$RDS_SUBNET_GROUP" \
    --no-multi-az \
    --backup-retention-period 7 \
    --no-publicly-accessible \
    --tags "Key=Name,Value=${PREFIX}" \
    --region "$REGION" > /dev/null

  echo "Waiting for RDS to become available (this takes 5-10 minutes)..."
  aws rds wait db-instance-available --db-instance-identifier "$RDS_IDENTIFIER" --region "$REGION"
else
  echo "RDS instance '${RDS_IDENTIFIER}' already exists (status: ${RDS_STATUS})"
fi

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$RDS_IDENTIFIER" \
  --query "DBInstances[0].Endpoint.Address" --output text --region "$REGION")
echo "RDS Endpoint: ${RDS_ENDPOINT}"

# ── S3 bucket ────────────────────────────────────────────────────────
if aws s3api head-bucket --bucket "$S3_BUCKET" --region "$REGION" &>/dev/null; then
  echo "S3 bucket '${S3_BUCKET}' already exists"
else
  echo "Creating S3 bucket '${S3_BUCKET}'"
  aws s3api create-bucket \
    --bucket "$S3_BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=${REGION}" > /dev/null

  aws s3api put-public-access-block \
    --bucket "$S3_BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$REGION"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  Tatl staging provisioning complete!"
echo "============================================================"
echo ""
echo "EC2 Instance ID : ${INSTANCE_ID}"
echo "Elastic IP      : ${EIP_PUBLIC}"
echo "RDS Endpoint    : ${RDS_ENDPOINT}"
echo "RDS Database    : ${RDS_DB_NAME}"
echo "RDS User        : ${RDS_MASTER_USER}"
echo "S3 Bucket       : ${S3_BUCKET}"
echo "SSH Key         : ${KEY_FILE}"
echo ""
echo "Next steps:"
echo "  1. SSH in:  ssh -i ${KEY_FILE} ubuntu@${EIP_PUBLIC}"
echo "  2. Run the server setup script:  infra/scripts/setup-server.sh"
echo "  3. Add these GitHub Secrets:"
echo "     STAGING_HOST     = ${EIP_PUBLIC}"
echo "     STAGING_SSH_KEY  = (contents of ${KEY_FILE})"
echo "     RAILS_MASTER_KEY = (from apps/portal/config/master.key)"
echo "     TATL_DB_HOST     = ${RDS_ENDPOINT}"
echo "     TATL_DB_PASSWORD = (the password you entered above)"
echo ""
