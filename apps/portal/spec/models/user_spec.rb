# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "associations" do
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:properties).through(:memberships) }
    it { is_expected.to have_many(:uploaded_documents).class_name("Document").dependent(:nullify) }
    it { is_expected.to have_one_attached(:avatar) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it "defines the role enum" do
      expect(described_class.roles.keys).to match_array(%w[resident board treasurer admin])
    end

    it "defaults to resident" do
      expect(described_class.new.role).to eq("resident")
    end
  end

  describe "factory" do
    it "builds a valid user" do
      expect(build(:user)).to be_valid
    end

    %i[board treasurer admin].each do |role|
      it "builds a valid #{role}" do
        user = build(:user, role)
        expect(user).to be_valid
        expect(user.public_send("#{role}?")).to be true
      end
    end
  end

  describe "#staff?" do
    it "is true for board, treasurer, and admin" do
      expect(build(:user, :board)).to be_staff
      expect(build(:user, :treasurer)).to be_staff
      expect(build(:user, :admin)).to be_staff
    end

    it "is false for residents" do
      expect(build(:user)).not_to be_staff
    end
  end

  describe "#display_name" do
    it "returns the full name when present" do
      user = build(:user, first_name: "Ada", last_name: "Lovelace")
      expect(user.display_name).to eq("Ada Lovelace")
    end

    it "falls back to email when names are blank" do
      user = build(:user, first_name: "", last_name: "")
      expect(user.display_name).to eq(user.email)
    end
  end

  describe "#initials" do
    it "returns the uppercased first letter of each name part" do
      user = build(:user, first_name: "Ada", last_name: "Lovelace")
      expect(user.initials).to eq("AL")
    end

    it "uses just the first name when last name is blank" do
      user = build(:user, first_name: "Ada", last_name: "")
      expect(user.initials).to eq("A")
    end

    it "falls back to the first letter of the email when both names are blank" do
      user = build(:user, first_name: "", last_name: "", email: "noreply@tatl.example")
      expect(user.initials).to eq("N")
    end
  end

  describe "avatar validation" do
    let(:user) { create(:user) }

    def attach_avatar(content_type:, byte_size: 100)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("x" * byte_size),
        filename: "avatar.bin",
        content_type: content_type
      )
      user.avatar.attach(blob)
    end

    it "is valid with a PNG attachment" do
      attach_avatar(content_type: "image/png")
      expect(user).to be_valid
    end

    it "is valid with a JPEG attachment" do
      attach_avatar(content_type: "image/jpeg")
      expect(user).to be_valid
    end

    it "rejects non-image attachments" do
      attach_avatar(content_type: "application/pdf")
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include(a_string_matching(/PNG, JPEG, GIF, or WebP/))
    end

    it "rejects attachments larger than 5 MB" do
      attach_avatar(content_type: "image/png")
      allow(user.avatar).to receive(:byte_size).and_return(6.megabytes)
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include(a_string_matching(/smaller than 5 MB/))
    end
  end

  describe "#remove_avatar" do
    let(:user) { create(:user) }

    before do
      user.avatar.attach(
        io: StringIO.new("png"), filename: "avatar.png", content_type: "image/png"
      )
    end

    it "purges the avatar after save when set to '1'" do
      expect(user.avatar).to be_attached

      user.update!(remove_avatar: "1")

      expect(user.reload.avatar).not_to be_attached
    end

    it "leaves the avatar attached when set to '0'" do
      user.update!(remove_avatar: "0")

      expect(user.reload.avatar).to be_attached
    end

    it "is a no-op when no avatar is attached" do
      user.avatar.purge
      expect { user.update!(remove_avatar: "1") }.not_to raise_error
    end
  end

  describe "Devise modules" do
    it "includes the configured modules" do
      expect(described_class.devise_modules).to include(
        :database_authenticatable,
        :registerable,
        :recoverable,
        :rememberable,
        :validatable,
        :confirmable,
        :lockable,
        :trackable
      )
    end
  end
end
