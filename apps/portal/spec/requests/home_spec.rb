# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    it "renders the landing page for guests" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome to NeIQhbor")
      expect(response.body).to include("Sign up")
    end

    it "greets a signed-in user with their role" do
      user = create(:user, :board, first_name: "Ada", last_name: "Lovelace")
      sign_in user

      get root_path
      expect(response.body).to include("Ada Lovelace")
      expect(response.body).to include("Board")
    end
  end

  describe "GET /up" do
    it "returns 200" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end
end
