# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Confirmation" do
  it "resends confirmation and confirms via token link" do
    unconfirmed = create(:user, :unconfirmed)
    ActionMailer::Base.deliveries.clear

    visit new_user_confirmation_path
    fill_in "Email", with: unconfirmed.email
    click_button "Resend confirmation"

    expect(page).to have_content("receive an email with instructions")
    expect(ActionMailer::Base.deliveries.size).to eq(1)

    token = extract_token_from_email(:confirmation_token)
    visit user_confirmation_path(confirmation_token: token)

    expect(unconfirmed.reload).to be_confirmed
    expect(page).to have_current_path(new_user_session_path)
  end

  it "shows error for an invalid confirmation token" do
    visit user_confirmation_path(confirmation_token: "bogus-token")
    expect(page).to have_content("Confirmation token")
  end

  it "navigates to resend confirmation from sign-in page" do
    visit new_user_session_path
    click_link "Didn't receive confirmation instructions?"

    expect(page).to have_content("Resend confirmation email")
  end
end
