# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Confirmation" do
  describe "GET /users/confirmation/new" do
    it "renders the resend confirmation form" do
      get new_user_confirmation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Resend confirmation")
    end
  end

  describe "POST /users/confirmation" do
    it "resends a confirmation email for an unconfirmed user" do
      user = create(:user, :unconfirmed)

      expect do
        post user_confirmation_path, params: { user: { email: user.email } }
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "re-renders the form for an unknown email" do
      post user_confirmation_path, params: { user: { email: "nobody@example.com" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/confirmation?confirmation_token=..." do
    it "confirms the user with a valid token" do
      user = create(:user, :unconfirmed)
      token = user.confirmation_token

      get user_confirmation_path(confirmation_token: token)

      user.reload
      expect(user).to be_confirmed
      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects an invalid token" do
      get user_confirmation_path(confirmation_token: "bogus")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Resend confirmation")
    end
  end
end
