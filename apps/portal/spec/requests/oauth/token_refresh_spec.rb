# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OAuth token refresh" do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }

  describe "POST /oauth/token with grant_type=refresh_token" do
    let(:token_response) { perform_oauth_authorization(user, application) }
    let(:client_secret) { application.plaintext_secret || application.secret }

    def refresh_tokens(refresh_token)
      post "/oauth/token", params: {
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: application.uid,
        client_secret: client_secret
      }
    end

    it "issues a new access token" do
      refresh_tokens(token_response["refresh_token"])

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["access_token"]).to be_present
      expect(response.parsed_body["access_token"]).not_to eq(token_response["access_token"])
    end

    it "returns a new refresh token" do
      refresh_tokens(token_response["refresh_token"])

      expect(response.parsed_body["refresh_token"]).to be_present
    end

    it "rejects an invalid refresh token" do
      refresh_tokens("invalid_token")

      expect(response).to have_http_status(:bad_request)
    end
  end
end
