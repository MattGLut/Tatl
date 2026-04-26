# frozen_string_literal: true

module SystemHelpers
  # Extract a Devise token from the last delivered email.
  # token_param should be :confirmation_token, :reset_password_token, or :unlock_token
  def extract_token_from_email(token_param)
    email = ActionMailer::Base.deliveries.last
    raise "No emails delivered" unless email

    body = email.body.encoded
    match = body.match(/#{token_param}=([^"&\s]+)/)
    raise "Token param #{token_param} not found in email body" unless match

    match[1]
  end

  def sign_up_via_form(first_name:, last_name:, email:, password:)
    visit new_user_registration_path
    fill_in "First name", with: first_name
    fill_in "Last name", with: last_name
    fill_in "Email", with: email
    fill_in "Password", with: password, match: :first
    fill_in "Password confirmation", with: password
    click_button "Create account"
  end

  def sign_in_via_form(email:, password:)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Sign in"
  end

  # Full sign-up + email confirmation flow. Returns the created User.
  def sign_up_and_confirm(first_name: "Test", last_name: "User", email: "test@tatl.example",
                          password: "Tatl-Password-1!")
    sign_up_via_form(first_name: first_name, last_name: last_name, email: email, password: password)
    token = extract_token_from_email(:confirmation_token)
    visit user_confirmation_path(confirmation_token: token)
    User.find_by!(email: email)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
