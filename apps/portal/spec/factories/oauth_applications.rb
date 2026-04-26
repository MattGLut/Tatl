# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: "Doorkeeper::Application" do
    sequence(:name) { |n| "Test App #{n}" }
    redirect_uri { "https://app.example.com/auth/callback" }
    scopes { "openid profile email" }
    confidential { true }
  end
end
