# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OpenID Connect Discovery" do
  describe "GET /.well-known/openid-configuration" do
    before { get "/.well-known/openid-configuration" }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON" do
      expect(response.content_type).to include("application/json")
    end

    it "includes the configured issuer" do
      body = response.parsed_body
      expect(body["issuer"]).to eq(ENV.fetch("OIDC_ISSUER", "http://localhost:3000"))
    end

    it "advertises the authorization endpoint" do
      body = response.parsed_body
      expect(body["authorization_endpoint"]).to end_with("/oauth/authorize")
    end

    it "advertises the token endpoint" do
      body = response.parsed_body
      expect(body["token_endpoint"]).to end_with("/oauth/token")
    end

    it "advertises the userinfo endpoint" do
      body = response.parsed_body
      expect(body["userinfo_endpoint"]).to end_with("/oauth/userinfo")
    end

    it "advertises the JWKS URI" do
      body = response.parsed_body
      expect(body["jwks_uri"]).to end_with("/oauth/discovery/keys")
    end

    it "lists supported scopes including openid" do
      body = response.parsed_body
      expect(body["scopes_supported"]).to include("openid")
    end

    it "lists supported response types" do
      body = response.parsed_body
      expect(body["response_types_supported"]).to include("code")
    end

    it "lists claims_supported including the custom roles claim" do
      body = response.parsed_body
      expect(body["claims_supported"]).to include("roles")
    end

    it "lists standard identity claims" do
      body = response.parsed_body
      %w[sub iss email name given_name family_name].each do |claim|
        expect(body["claims_supported"]).to include(claim)
      end
    end
  end
end
