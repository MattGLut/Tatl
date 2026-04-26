# frozen_string_literal: true

# rubocop:disable Style/SymbolProc -- Doorkeeper DSL blocks receive multiple args; &:method would forward extras
Doorkeeper::OpenidConnect.configure do
  issuer do |_resource_owner, _application|
    ENV.fetch("OIDC_ISSUER", "http://localhost:3000")
  end

  subject do |resource_owner, _application|
    resource_owner.id.to_s
  end

  # Dev/test: auto-generate an ephemeral RSA key.
  # Staging/production: set OIDC_SIGNING_KEY env var (see rake oidc:generate_signing_key).
  signing_key ENV.fetch("OIDC_SIGNING_KEY") { OpenSSL::PKey::RSA.generate(2048).to_pem }
  signing_algorithm :rs256

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    resource_owner.current_sign_in_at
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    store_location_for(resource_owner, return_to)
    sign_out(resource_owner)
    redirect_to new_user_session_url
  end

  subject_types_supported [:public]

  claims do
    claim :email do |resource_owner|
      resource_owner.email
    end

    claim :email_verified do |resource_owner|
      resource_owner.confirmed_at.present?
    end

    claim :name do |resource_owner|
      resource_owner.full_name
    end

    claim :given_name do |resource_owner|
      resource_owner.first_name
    end

    claim :family_name do |resource_owner|
      resource_owner.last_name
    end

    claim :roles, response: %i[id_token user_info] do |resource_owner|
      [resource_owner.role]
    end
  end
end
# rubocop:enable Style/SymbolProc
