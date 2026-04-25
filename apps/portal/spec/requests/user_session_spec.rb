# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Session" do
  let(:user) { create(:user, password: "Tatl-Password-1!") }

  describe "GET /users/sign_in" do
    it "renders the sign-in form" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")
      expect(response.body).to include("Welcome back")
    end
  end

  describe "POST /users/sign_in" do
    it "signs in a confirmed user with valid credentials" do
      post user_session_path, params: {
        user: { email: user.email, password: "Tatl-Password-1!" }
      }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(user.display_name)
    end

    it "rejects invalid credentials" do
      post user_session_path, params: {
        user: { email: user.email, password: "wrong" }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Sign in")
    end

    it "rejects an unconfirmed user" do
      unconfirmed = create(:user, :unconfirmed, password: "Tatl-Password-1!")

      post user_session_path, params: {
        user: { email: unconfirmed.email, password: "Tatl-Password-1!" }
      }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /users/sign_out" do
    it "signs out the current user" do
      sign_in user
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
