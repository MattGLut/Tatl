# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC JWKS endpoint" do
  describe "GET /oauth/discovery/keys" do
    before { get "/oauth/discovery/keys" }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a JWK Set with at least one key" do
      body = response.parsed_body
      expect(body["keys"]).to be_an(Array)
      expect(body["keys"].size).to be >= 1
    end

    it "contains an RSA key" do
      body = response.parsed_body
      key = body["keys"].first
      expect(key["kty"]).to eq("RSA")
      expect(key["n"]).to be_present
      expect(key["e"]).to be_present
    end

    it "includes the key ID" do
      body = response.parsed_body
      key = body["keys"].first
      expect(key["kid"]).to be_present
    end
  end
end
