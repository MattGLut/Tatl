# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC UserInfo endpoint" do
  let(:user) { create(:user, first_name: "Jane", last_name: "Doe", role: :board) }
  let(:application) { create(:oauth_application) }

  describe "GET /oauth/userinfo" do
    context "with a valid Bearer token" do
      let(:access_token) do
        Doorkeeper::AccessToken.create!(
          resource_owner_id: user.id,
          application: application,
          scopes: "openid profile email",
          expires_in: 1.hour
        )
      end

      before do
        get "/oauth/userinfo", headers: { "Authorization" => "Bearer #{access_token.token}" }
      end

      it "returns 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the sub claim" do
        body = response.parsed_body
        expect(body["sub"]).to eq(user.id.to_s)
      end

      it "returns the email claim" do
        body = response.parsed_body
        expect(body["email"]).to eq(user.email)
      end

      it "returns the name claim" do
        body = response.parsed_body
        expect(body["name"]).to eq("Jane Doe")
      end

      it "returns given_name and family_name" do
        body = response.parsed_body
        expect(body["given_name"]).to eq("Jane")
        expect(body["family_name"]).to eq("Doe")
      end

      it "returns the custom roles claim" do
        body = response.parsed_body
        expect(body["roles"]).to eq(["board"])
      end

      it "returns email_verified" do
        body = response.parsed_body
        expect(body["email_verified"]).to be(true)
      end
    end

    context "without a token" do
      it "returns 401" do
        get "/oauth/userinfo"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an expired token" do
      let(:expired_token) do
        Doorkeeper::AccessToken.create!(
          resource_owner_id: user.id,
          application: application,
          scopes: "openid profile email",
          expires_in: 0,
          created_at: 1.hour.ago
        )
      end

      it "returns 401" do
        get "/oauth/userinfo", headers: { "Authorization" => "Bearer #{expired_token.token}" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
