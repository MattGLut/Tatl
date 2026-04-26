# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account Unlock" do
  let(:password) { "Tatl-Password-1!" }

  it "locks account after too many failures and unlocks via email token" do
    user = create(:user, password: password, failed_attempts: Devise.maximum_attempts - 1)

    # One more failed attempt triggers the lock
    sign_in_via_form(email: user.email, password: "wrong-password")
    expect(page).to have_content("locked")
    expect(user.reload).to be_access_locked

    expect(ActionMailer::Base.deliveries.size).to eq(1)

    # Unlock via the token in the email
    token = extract_token_from_email(:unlock_token)
    visit user_unlock_path(unlock_token: token)

    expect(user.reload).not_to be_access_locked

    # Can sign in again
    sign_in_via_form(email: user.email, password: password)
    expect(page).to have_content("Hi, #{user.display_name}")
  end

  it "allows requesting unlock instructions for a locked account" do
    locked_user = create(:user, :locked, password: password)
    ActionMailer::Base.deliveries.clear

    visit new_user_unlock_path
    fill_in "Email", with: locked_user.email
    click_button "Send unlock instructions"

    expect(page).to have_content("receive an email with instructions")
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "shows error for an invalid unlock token" do
    visit user_unlock_path(unlock_token: "bogus-token")
    expect(page).to have_content("Unlock token")
  end
end
