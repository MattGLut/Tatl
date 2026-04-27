# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User account update" do
  let(:password) { "Tatl-Password-1!" }
  let(:user) do
    create(:user,
           first_name: "Ada",
           last_name: "Lovelace",
           email: "ada@tatl.example",
           password: password,
           password_confirmation: password)
  end

  before { sign_in user }

  def png_upload
    Rack::Test::UploadedFile.new(
      StringIO.new("png-bytes"),
      "image/png",
      true,
      original_filename: "avatar.png"
    )
  end

  describe "PUT /users (profile-only updates)" do
    it "updates name without requiring current_password" do
      put user_registration_path, params: {
        user: { first_name: "Grace", last_name: "Hopper" }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.first_name).to eq("Grace")
      expect(user.last_name).to eq("Hopper")
    end

    it "uploads an avatar without requiring current_password" do
      put user_registration_path, params: {
        user: { avatar: png_upload }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.avatar).to be_attached
      expect(user.avatar.content_type).to eq("image/png")
    end

    it "rejects an avatar with an unsupported content type" do
      pdf = Rack::Test::UploadedFile.new(
        StringIO.new("not an image"), "application/pdf", true,
        original_filename: "doc.pdf"
      )

      put user_registration_path, params: { user: { avatar: pdf } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.avatar).not_to be_attached
    end

    it "removes the existing avatar when remove_avatar is checked" do
      user.avatar.attach(
        io: StringIO.new("png"), filename: "avatar.png", content_type: "image/png"
      )

      put user_registration_path, params: {
        user: { remove_avatar: "1" }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.avatar).not_to be_attached
    end

    it "lets users opt out of announcement emails without current_password" do
      expect(user.announcement_emails_enabled).to be(true)

      put user_registration_path, params: {
        user: { announcement_emails_enabled: "0" }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.announcement_emails_enabled).to be(false)
    end
  end

  describe "PUT /users (email change)" do
    it "rejects an email change without current_password" do
      put user_registration_path, params: {
        user: { email: "new@tatl.example" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.unconfirmed_email).to be_nil
    end

    it "triggers reconfirmation when current_password is supplied" do
      put user_registration_path, params: {
        user: { email: "new@tatl.example", current_password: password }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.unconfirmed_email).to eq("new@tatl.example")
    end
  end

  describe "PUT /users (password change)" do
    let(:new_password) { "Brand-New-Pass-1!" }

    it "rejects a password change without current_password" do
      put user_registration_path, params: {
        user: { password: new_password, password_confirmation: new_password }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.valid_password?(new_password)).to be(false)
    end

    it "updates the password when current_password is supplied" do
      put user_registration_path, params: {
        user: {
          password: new_password,
          password_confirmation: new_password,
          current_password: password
        }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.valid_password?(new_password)).to be(true)
    end
  end

  describe "DELETE /users" do
    it "is forbidden by Pundit and does not destroy the user" do
      expect do
        delete user_registration_path
      end.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("pundit.not_authorized"))
    end
  end
end
