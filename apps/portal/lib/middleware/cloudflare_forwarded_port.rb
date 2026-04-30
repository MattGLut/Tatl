# frozen_string_literal: true

module Middleware
  # When Cloudflare proxies to Puma on a high port (e.g. 8000), Rack builds
  # request.base_url as https://example.com:8000 while the browser sends
  # Origin: https://example.com — so Rails' forgery_protection_origin_check
  # rejects POSTs (including Devise sign-in). Align forwarded port with the
  # visitor-facing scheme using Cloudflare's request headers.
  class CloudflareForwardedPort
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["HTTP_CF_RAY"].present?
        proto = env["HTTP_X_FORWARDED_PROTO"].to_s.split(",").map(&:strip).last.presence
        env["HTTP_X_FORWARDED_PORT"] = client_forwarded_port(proto) if proto
      end
      @app.call(env)
    end

    private

    def client_forwarded_port(proto)
      proto == "https" ? "443" : "80"
    end
  end
end
