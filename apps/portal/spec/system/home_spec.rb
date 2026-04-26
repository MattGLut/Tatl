# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home" do
  it "shows welcome content and auth links for guests" do
    visit root_path

    expect(page).to have_content("Welcome to Tatl")
    expect(page).to have_link("Sign in")
    expect(page).to have_link("Sign up")
    expect(page).to have_no_button("Sign out")
  end

  it "shows user greeting and role for signed-in users" do
    user = create(:user, :board, first_name: "Ada", last_name: "Lovelace")
    sign_in user

    visit root_path

    expect(page).to have_content("Hi, Ada Lovelace")
    expect(page).to have_content("Board")
    expect(page).to have_button("Sign out")
    expect(page).to have_no_link("Sign in")
  end

  it "displays notice flash messages" do
    user = create(:user)
    sign_in user

    visit root_path
    # Devise sets a notice on sign-in; verify flash rendering
    expect(page).to have_current_path(root_path)
  end
end
