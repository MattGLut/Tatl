# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session" do
  let(:password) { "Tatl-Password-1!" }
  let(:user) { create(:user, password: password) }

  it "signs in a confirmed user and shows greeting" do
    sign_in_via_form(email: user.email, password: password)

    expect(page).to have_content("Hi, #{user.display_name}")
    expect(page).to have_current_path(root_path)
  end

  it "signs out and returns to guest view" do
    sign_in user
    visit root_path
    expect(page).to have_content("Hi, #{user.display_name}")

    within "nav[aria-label='Main']" do
      click_button "Sign out"
    end

    expect(page).to have_current_path(root_path)
    expect(page).to have_link("Sign in")
    expect(page).to have_link("Sign up")
    expect(page).to have_no_content("Hi, #{user.display_name}")
  end

  it "shows error for invalid password" do
    sign_in_via_form(email: user.email, password: "wrong-password")

    expect(page).to have_content("Invalid email or password")
    expect(page).to have_current_path(new_user_session_path)
  end

  it "rejects an unconfirmed user" do
    unconfirmed = create(:user, :unconfirmed, password: password)

    sign_in_via_form(email: unconfirmed.email, password: password)

    expect(page).to have_content("confirm")
  end

  it "displays the remember me checkbox" do
    visit new_user_session_path
    expect(page).to have_field("Remember me")
  end
end
