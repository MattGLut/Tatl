# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile" do
  let(:password) { "Tatl-Password-1!" }
  let(:user) { create(:user, first_name: "Ada", last_name: "Lovelace", password: password) }

  before { sign_in user }

  it "is reachable from the header dropdown" do
    visit root_path

    within "nav[aria-label='Main']" do
      expect(page).to have_link("Account settings", href: edit_user_registration_path)
      click_link "Account settings"
    end

    expect(page).to have_current_path(edit_user_registration_path)
    expect(page).to have_text("Account settings")
  end

  it "updates first and last name without requiring the current password" do
    visit edit_user_registration_path

    fill_in "First name", with: "Grace"
    fill_in "Last name", with: "Hopper"
    click_button "Save profile"

    expect(page).to have_text("Hi, Grace Hopper")
    expect(user.reload.first_name).to eq("Grace")
  end

  it "uploads an avatar and shows it in the header" do
    visit edit_user_registration_path

    avatar_path = Rails.root.join("tmp/spec_avatar.png")
    File.binwrite(avatar_path, "fake-png-bytes")

    attach_file "user[avatar]", avatar_path.to_s
    click_button "Save profile"

    expect(user.reload.avatar).to be_attached
    expect(page).to have_css("header img[alt*='avatar']")
  ensure
    FileUtils.rm_f(avatar_path) if avatar_path
  end

  it "removes an attached avatar via the checkbox" do
    user.avatar.attach(io: StringIO.new("png"), filename: "avatar.png", content_type: "image/png")

    visit edit_user_registration_path
    check "Remove current photo"
    click_button "Save profile"

    expect(user.reload.avatar).not_to be_attached
  end

  it "changes password and can sign in with the new one" do
    visit edit_user_registration_path

    within("section", text: "Security") do
      fill_in "New password", with: "Brand-New-Pass-1!"
      fill_in "Confirm new password", with: "Brand-New-Pass-1!"
      fill_in "Current password", with: password
      click_button "Update password"
    end

    expect(page).to have_current_path(root_path)

    within "nav[aria-label='Main']" do
      click_button "Sign out"
    end
    sign_in_via_form(email: user.email, password: "Brand-New-Pass-1!")
    expect(page).to have_text("Hi, Ada Lovelace")
  end

  it "rejects a password change without the current password" do
    visit edit_user_registration_path

    within("section", text: "Security") do
      fill_in "New password", with: "Brand-New-Pass-1!"
      fill_in "Confirm new password", with: "Brand-New-Pass-1!"
      click_button "Update password"
    end

    expect(page).to have_text("Current password")
    expect(page).to have_text("can't be blank")
  end

  it "shows pending reconfirmation when email changes with the current password" do
    visit edit_user_registration_path

    within("section", text: "Profile") do
      fill_in "Email", with: "new-email@tatl.example"
      fill_in "Current password", with: password
      click_button "Save profile"
    end

    expect(user.reload.unconfirmed_email).to eq("new-email@tatl.example")
  end

  it "does not expose a delete-account affordance" do
    visit edit_user_registration_path

    expect(page).to have_text("Account settings")
    expect(page).to have_no_button("Delete my account")
    expect(page).to have_no_link("Delete my account")
  end
end
