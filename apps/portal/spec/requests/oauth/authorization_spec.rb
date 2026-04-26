# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OAuth authorization code flow" do
  let(:user) { create(:user, :admin) }
  let(:application) { create(:oauth_application) }

  before { sign_in user }

  describe "full code exchange" do
    it "returns an access_token and id_token" do
      token_response = perform_oauth_authorization(user, application)

      expect(token_response["access_token"]).to be_present
      expect(token_response["token_type"]).to eq("Bearer")
      expect(token_response["id_token"]).to be_present
    end

    it "includes the correct sub claim in the id_token" do
      token_response = perform_oauth_authorization(user, application)
      claims = decode_id_token(token_response["id_token"])

      expect(claims["sub"]).to eq(user.id.to_s)
    end

    it "includes the correct iss claim in the id_token" do
      token_response = perform_oauth_authorization(user, application)
      claims = decode_id_token(token_response["id_token"])

      expect(claims["iss"]).to eq(ENV.fetch("OIDC_ISSUER", "http://localhost:3000"))
    end

    it "includes the custom roles claim in the id_token" do
      token_response = perform_oauth_authorization(user, application)
      claims = decode_id_token(token_response["id_token"])

      expect(claims["roles"]).to eq(["admin"])
    end

    it "includes aud matching the application uid" do
      token_response = perform_oauth_authorization(user, application)
      claims = decode_id_token(token_response["id_token"])

      expect(claims["aud"]).to eq(application.uid)
    end
  end

  describe "with different user roles" do
    %w[resident board treasurer].each do |role|
      it "embeds the #{role} role in the id_token" do
        role_user = create(:user, role: role)
        sign_in role_user

        token_response = perform_oauth_authorization(role_user, application)
        claims = decode_id_token(token_response["id_token"])

        expect(claims["roles"]).to eq([role])
      end
    end
  end

  describe "unauthenticated request" do
    it "redirects to sign in for the authorize endpoint" do
      sign_out user

      get "/oauth/authorize", params: {
        response_type: "code",
        client_id: application.uid,
        redirect_uri: application.redirect_uri,
        scope: "openid profile email"
      }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
