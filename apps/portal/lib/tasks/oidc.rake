# frozen_string_literal: true

namespace :oidc do # rubocop:disable Metrics/BlockLength
  desc "Generate an RSA 2048 PEM for OIDC_SIGNING_KEY (copy into .env.production)"
  task generate_signing_key: :environment do
    key = OpenSSL::PKey::RSA.generate(2048)
    puts key.to_pem
  end

  desc "Create or update OAuth applications for Zammad and Discourse"
  task seed_applications: :environment do
    apps = [
      {
        name: "Zammad",
        redirect_uri: ENV.fetch("ZAMMAD_OIDC_REDIRECT_URI", "https://zammad.example.com/auth/openid_connect/callback"),
        scopes: "openid profile email"
      },
      {
        name: "Discourse",
        redirect_uri: ENV.fetch("DISCOURSE_OIDC_REDIRECT_URI", "https://discourse.example.com/auth/oidc/callback"),
        scopes: "openid profile email"
      }
    ]

    apps.each do |attrs|
      app = Doorkeeper::Application.find_or_initialize_by(name: attrs[:name])
      app.redirect_uri = attrs[:redirect_uri]
      app.scopes = attrs[:scopes]
      app.save!

      puts "#{app.name}: uid=#{app.uid} secret=#{app.plaintext_secret || "(unchanged)"}"
    end
  end
end
