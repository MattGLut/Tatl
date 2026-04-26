# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Registration" do
  let(:valid_params) do
    {
      user: {
        first_name: "Ada",
        last_name: "Lovelace",
        email: "ada@tatl.example",
        password: "Tatl-Password-1!",
        password_confirmation: "Tatl-Password-1!"
      }
    }
  end

  describe "GET /users/sign_up" do
    it "renders the registration form" do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your account")
      expect(response.body).to include("First name")
      expect(response.body).to include("Last name")
    end
  end

  describe "POST /users" do
    it "creates an unconfirmed user and sends a confirmation email" do
      expect do
        post user_registration_path, params: valid_params
      end.to change(User, :count).by(1)
                                 .and change(ActionMailer::Base.deliveries, :count).by(1)

      user = User.last
      expect(user.email).to eq("ada@tatl.example")
      expect(user.first_name).to eq("Ada")
      expect(user.last_name).to eq("Lovelace")
      expect(user).not_to be_confirmed
    end

    it "sends a confirmation email to the correct address" do
      post user_registration_path, params: valid_params
      email = ActionMailer::Base.deliveries.last

      expect(email.to).to eq(["ada@tatl.example"])
      expect(email.subject).to match(/confirm/i)
    end

    it "rejects registration with missing first_name" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:first_name] = ""

      expect do
        post user_registration_path, params: invalid_params
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects registration with mismatched passwords" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:password_confirmation] = "wrong"

      expect do
        post user_registration_path, params: invalid_params
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects registration with a duplicate email" do
      create(:user, email: "ada@tatl.example")

      expect do
        post user_registration_path, params: valid_params
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects registration with missing last_name" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:last_name] = ""

      expect do
        post user_registration_path, params: invalid_params
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects registration with a password that is too short" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:password] = "short"
      invalid_params[:user][:password_confirmation] = "short"

      expect do
        post user_registration_path, params: invalid_params
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects registration with an invalid email format" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:email] = "not-an-email"

      expect do
        post user_registration_path, params: invalid_params
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
