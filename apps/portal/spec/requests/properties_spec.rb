# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Properties" do
  let(:admin) { create(:user, :admin) }
  let(:board_member) { create(:user, :board) }
  let(:resident) { create(:user) }

  describe "GET /properties" do
    it "requires authentication" do
      get properties_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows all properties to staff" do
      create(:property, name: "Unit 1")
      sign_in admin
      get properties_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unit 1")
    end

    it "shows only member properties to residents" do
      member_prop = create(:property, name: "My Unit")
      create(:property, name: "Other Unit")
      create(:membership, user: resident, property: member_prop)

      sign_in resident
      get properties_path
      expect(response.body).to include("My Unit")
      expect(response.body).not_to include("Other Unit")
    end
  end

  describe "GET /properties/:id" do
    let(:property) { create(:property) }

    it "allows staff to view any property" do
      sign_in admin
      get property_path(property)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(property.name)
    end

    it "allows a resident with active membership to view" do
      create(:membership, user: resident, property: property)
      sign_in resident
      get property_path(property)
      expect(response).to have_http_status(:ok)
    end

    it "denies a resident without membership" do
      sign_in resident
      get property_path(property)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /properties/new" do
    it "renders the form for staff" do
      sign_in board_member
      get new_property_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get new_property_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /properties" do
    let(:valid_params) { { property: { name: "Unit 99", property_type: "condo", lot_number: "L-99" } } }

    it "creates a property for staff" do
      sign_in admin
      expect { post properties_path, params: valid_params }.to change(Property, :count).by(1)
      expect(response).to redirect_to(property_path(Property.last))
    end

    it "re-renders the form on invalid data" do
      sign_in admin
      post properties_path, params: { property: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies creation for residents" do
      sign_in resident
      post properties_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /properties/:id" do
    let(:property) { create(:property) }

    it "updates for staff" do
      sign_in board_member
      patch property_path(property), params: { property: { name: "Updated Name" } }
      expect(response).to redirect_to(property_path(property))
      expect(property.reload.name).to eq("Updated Name")
    end

    it "denies update for residents" do
      sign_in resident
      patch property_path(property), params: { property: { name: "Hacked" } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /properties/:id" do
    let!(:property) { create(:property) }

    it "deletes for admins" do
      sign_in admin
      expect { delete property_path(property) }.to change(Property, :count).by(-1)
      expect(response).to redirect_to(properties_path)
    end

    it "denies deletion for board members" do
      sign_in board_member
      delete property_path(property)
      expect(response).to redirect_to(root_path)
    end

    it "denies deletion for residents" do
      sign_in resident
      delete property_path(property)
      expect(response).to redirect_to(root_path)
    end
  end
end
