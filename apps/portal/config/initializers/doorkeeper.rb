# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    current_user || begin
      session[:user_return_to] = request.fullpath
      redirect_to new_user_session_url
    end
  end

  admin_authenticator do
    if current_user&.admin?
      current_user
    else
      redirect_to root_url, alert: I18n.t("pundit.not_authorized")
    end
  end

  default_scopes :openid
  optional_scopes :profile, :email

  enforce_configured_scopes

  grant_flows %w[authorization_code]

  # Auth-code-only; no implicit or client_credentials
  access_token_expires_in 1.hour
  use_refresh_token

  # Allow non-SSL redirect URIs in development/staging (no domain + HTTPS yet).
  # TODO: remove once Cloudflare + Let's Encrypt are configured.
  force_ssl_in_redirect_uri !Rails.env.local?
end
