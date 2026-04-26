# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile" do
  let(:password) { "Tatl-Password-1!" }
  let(:user) { create(:user, first_name: "Ada", last_name: "Lovelace", password: password) }

  before { sign_in user }

  it "updates first and last name" do
    visit edit_user_registration_path

    fill_in "First name", with: "Grace"
    fill_in "Last name", with: "Hopper"
    fill_in "Current password", with: password
    click_button "Update"

    expect(page).to have_content("Hi, Grace Hopper")
  end

  it "changes password and can sign in with the new one" do
    visit edit_user_registration_path

    fill_in "New password", with: "Brand-New-Pass-1!", match: :first
    fill_in "Confirm new password", with: "Brand-New-Pass-1!"
    fill_in "Current password", with: password
    click_button "Update"

    expect(page).to have_current_path(root_path)

    # Sign out and sign in with new password
    click_button "Sign out"
    sign_in_via_form(email: user.email, password: "Brand-New-Pass-1!")
    expect(page).to have_content("Hi, Ada Lovelace")
  end

  it "shows pending reconfirmation when email changes" do
    visit edit_user_registration_path

    fill_in "Email", with: "new-email@tatl.example"
    fill_in "Current password", with: password
    click_button "Update"

    expect(user.reload.unconfirmed_email).to eq("new-email@tatl.example")
  end

  it "rejects update without current password" do
    visit edit_user_registration_path

    fill_in "First name", with: "Grace"
    click_button "Update"

    expect(page).to have_content("Current password")
    expect(page).to have_content("can't be blank")
  end

  it "deletes the account" do
    visit edit_user_registration_path

    click_button "Delete my account"

    expect(User.find_by(id: user.id)).to be_nil
    expect(page).to have_current_path(root_path)
  end
end
