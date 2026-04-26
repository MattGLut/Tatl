# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Password Reset" do
  let(:user) { create(:user) }

  it "walks through the full forgot-password and reset flow" do
    visit new_user_session_path
    click_link "Forgot your password?"

    fill_in "Email", with: user.email
    click_button "Send reset instructions"

    expect(page).to have_content("receive an email with instructions")
    expect(ActionMailer::Base.deliveries.size).to eq(1)

    token = extract_token_from_email(:reset_password_token)
    visit edit_user_password_path(reset_password_token: token)

    expect(page).to have_content("Set a new password")

    fill_in "New password", with: "Brand-New-Pass-1!"
    fill_in "Confirm new password", with: "Brand-New-Pass-1!"
    click_button "Reset password"

    # After reset, Devise signs the user in and redirects to root
    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Hi, #{user.display_name}")

    # Verify old password no longer works
    within "nav[aria-label='Main']" do
      click_button "Sign out"
    end
    sign_in_via_form(email: user.email, password: "Tatl-Password-1!")
    expect(page).to have_content("Invalid email or password")

    # New password works
    sign_in_via_form(email: user.email, password: "Brand-New-Pass-1!")
    expect(page).to have_content("Hi, #{user.display_name}")
  end

  it "shows errors for mismatched passwords on reset form" do
    token = user.send_reset_password_instructions
    ActionMailer::Base.deliveries.clear

    visit edit_user_password_path(reset_password_token: token)
    fill_in "New password", with: "Brand-New-Pass-1!"
    fill_in "Confirm new password", with: "something-different"
    click_button "Reset password"

    expect(page).to have_content("match")
  end

  it "shows error for an invalid reset token" do
    visit edit_user_password_path(reset_password_token: "bogus-token")
    fill_in "New password", with: "Brand-New-Pass-1!"
    fill_in "Confirm new password", with: "Brand-New-Pass-1!"
    click_button "Reset password"

    expect(page).to have_content("Reset password token")
  end
end
