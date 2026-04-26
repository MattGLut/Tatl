# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Unlock" do
  describe "GET /users/unlock/new" do
    it "renders the unlock form" do
      get new_user_unlock_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unlock your account")
    end
  end

  describe "POST /users/unlock" do
    it "sends unlock instructions for a locked user" do
      user = create(:user, :locked)

      expect do
        post user_unlock_path, params: { user: { email: user.email } }
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "re-renders the form for an unknown email" do
      post user_unlock_path, params: { user: { email: "nobody@example.com" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/unlock?unlock_token=..." do
    it "unlocks the account with a valid token" do
      user = create(:user, :locked)
      raw_token = user.send_unlock_instructions
      ActionMailer::Base.deliveries.clear

      get user_unlock_path(unlock_token: raw_token)

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload).not_to be_access_locked
    end

    it "rejects an invalid unlock token" do
      get user_unlock_path(unlock_token: "bogus-token")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unlock token")
    end
  end
end
