# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registration" do
  it "walks through the full sign-up and confirmation journey" do
    visit new_user_registration_path

    fill_in "First name", with: "Ada"
    fill_in "Last name", with: "Lovelace"
    fill_in "Email", with: "ada@tatl.example"
    fill_in "Password", with: "Tatl-Password-1!", match: :first
    fill_in "Password confirmation", with: "Tatl-Password-1!"
    click_button "Create account"

    expect(page).to have_content("confirmation link")
    expect(ActionMailer::Base.deliveries.size).to eq(1)

    # Cannot sign in before confirming
    sign_in_via_form(email: "ada@tatl.example", password: "Tatl-Password-1!")
    expect(page).to have_content("confirm")

    # Confirm via token from email
    token = extract_token_from_email(:confirmation_token)
    visit user_confirmation_path(confirmation_token: token)

    # Now sign in succeeds
    sign_in_via_form(email: "ada@tatl.example", password: "Tatl-Password-1!")
    expect(page).to have_content("Ada Lovelace")
  end

  describe "validation errors" do
    it "shows error when first name is blank" do
      sign_up_via_form(first_name: "", last_name: "Lovelace", email: "ada@tatl.example", password: "Tatl-Password-1!")
      expect(page).to have_content("First name")
      expect(page).to have_content("can't be blank")
    end

    it "shows error when last name is blank" do
      sign_up_via_form(first_name: "Ada", last_name: "", email: "ada@tatl.example", password: "Tatl-Password-1!")
      expect(page).to have_content("Last name")
      expect(page).to have_content("can't be blank")
    end

    it "shows error when password is too short" do
      sign_up_via_form(first_name: "Ada", last_name: "Lovelace", email: "ada@tatl.example", password: "short")
      expect(page).to have_content("Password")
      expect(page).to have_content("too short")
    end

    it "shows error when passwords do not match" do
      visit new_user_registration_path
      fill_in "First name", with: "Ada"
      fill_in "Last name", with: "Lovelace"
      fill_in "Email", with: "ada@tatl.example"
      fill_in "Password", with: "Tatl-Password-1!", match: :first
      fill_in "Password confirmation", with: "something-else"
      click_button "Create account"

      expect(page).to have_content("Password confirmation")
      expect(page).to have_content("match")
    end

    it "shows error when email is already taken" do
      create(:user, email: "ada@tatl.example")
      sign_up_via_form(first_name: "Ada", last_name: "Lovelace", email: "ada@tatl.example",
                       password: "Tatl-Password-1!")
      expect(page).to have_content("Email")
      expect(page).to have_content("already been taken")
    end
  end
end
