# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Password Reset" do
  let(:user) { create(:user) }

  describe "GET /users/password/new" do
    it "renders the forgot password form" do
      get new_user_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Forgot your password?")
    end
  end

  describe "POST /users/password" do
    it "sends a reset email for a known user" do
      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(response).to redirect_to(new_user_session_path)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([user.email])
      expect(email.subject).to match(/reset/i)
    end

    it "re-renders the form for an unknown email" do
      post user_password_path, params: { user: { email: "nobody@example.com" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/password/edit?reset_password_token=..." do
    it "renders the reset form with a valid token" do
      token = user.send_reset_password_instructions
      ActionMailer::Base.deliveries.clear

      get edit_user_password_path(reset_password_token: token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Set a new password")
    end
  end

  describe "PUT /users/password" do
    it "resets the password with a valid token" do
      token = user.send_reset_password_instructions
      ActionMailer::Base.deliveries.clear

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "NewSecure-Pass-1!",
          password_confirmation: "NewSecure-Pass-1!"
        }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.valid_password?("NewSecure-Pass-1!")).to be true
    end

    it "rejects mismatched passwords" do
      token = user.send_reset_password_instructions
      ActionMailer::Base.deliveries.clear

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "NewSecure-Pass-1!",
          password_confirmation: "different"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an invalid reset token" do
      put user_password_path, params: {
        user: {
          reset_password_token: "bogus-token",
          password: "NewSecure-Pass-1!",
          password_confirmation: "NewSecure-Pass-1!"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a password that is too short" do
      token = user.send_reset_password_instructions
      ActionMailer::Base.deliveries.clear

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "short",
          password_confirmation: "short"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
