# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    it "renders the landing page for guests" do
      get root_path
      expect(response).to have_http_status(:ok)
      heading_text = response.parsed_body.at_css("h1")&.text
      expect(heading_text).to include("Welcome to neiQhbor")
      expect(response.body).to include("Sign up")
      expect(response.body).not_to include("Community overview")
    end

    it "renders a staff dashboard for board members" do
      user = create(:user, :board, first_name: "Ada", last_name: "Lovelace")
      sign_in user

      get root_path
      expect(response.body).to include("Hi, Ada Lovelace")
      expect(response.body).to include("Community overview")
      expect(response.body).to include("Support tickets")
    end

    it "renders a resident dashboard for residents" do
      user = create(:user, first_name: "Rae", last_name: "Resident")
      sign_in user

      get root_path
      expect(response.body).to include("Your account")
      expect(response.body).to include("Your tickets")
    end
  end

  describe "GET /up" do
    it "returns 200" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end
end
