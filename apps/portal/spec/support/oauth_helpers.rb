# frozen_string_literal: true

module OauthHelpers
  # Performs a full OAuth authorization code exchange and returns the parsed
  # token response body (keys: "access_token", "refresh_token", "id_token", etc.)
  def perform_oauth_authorization(user, application, scopes: "openid profile email")
    # Step 1: GET /oauth/authorize to obtain an authorization code.
    # Doorkeeper auto-grants for previously authorized scopes if skip_authorization
    # is not configured, so we pre-authorize to avoid the consent form.
    grant = Doorkeeper::AccessGrant.create!(
      resource_owner_id: user.id,
      application: application,
      redirect_uri: application.redirect_uri,
      expires_in: 600,
      scopes: scopes
    )

    # Step 2: Exchange the auth code for tokens.
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: grant.token,
      redirect_uri: application.redirect_uri,
      client_id: application.uid,
      client_secret: application.plaintext_secret || application.secret
    }

    JSON.parse(response.body)
  end

  # Decodes an OIDC id_token JWT using the app's signing key.
  def decode_id_token(id_token)
    pem = Doorkeeper::OpenidConnect.configuration.signing_key
    rsa_key = OpenSSL::PKey::RSA.new(pem)
    JWT.decode(id_token, rsa_key.public_key, true, algorithms: ["RS256"]).first
  end
end

RSpec.configure do |config|
  config.include OauthHelpers, type: :request
end
