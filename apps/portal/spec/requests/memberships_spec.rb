# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memberships" do
  let(:admin) { create(:user, :admin) }
  let(:board_member) { create(:user, :board) }
  let(:resident) { create(:user) }
  let(:property) { create(:property) }
  let(:target_user) { create(:user) }

  describe "GET /properties/:property_id/memberships/new" do
    it "renders the form for staff" do
      sign_in admin
      get new_property_membership_path(property)
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get new_property_membership_path(property)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /properties/:property_id/memberships/:id/edit" do
    let!(:membership) { create(:membership, property: property) }

    it "renders the form for staff" do
      sign_in admin
      get edit_property_membership_path(property, membership)
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get edit_property_membership_path(property, membership)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /properties/:property_id/memberships" do
    let(:valid_params) do
      { membership: { user_id: target_user.id, role: "owner", started_on: Date.current.to_s } }
    end

    it "creates a membership for staff" do
      sign_in admin
      expect { post property_memberships_path(property), params: valid_params }.to change(Membership, :count).by(1)
      expect(response).to redirect_to(property_path(property))
    end

    it "re-renders on invalid data" do
      sign_in admin
      post property_memberships_path(property),
           params: { membership: { user_id: target_user.id, role: "owner", started_on: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies creation for residents" do
      sign_in resident
      post property_memberships_path(property), params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /properties/:property_id/memberships/:id" do
    let!(:membership) { create(:membership, property: property) }

    it "updates for staff" do
      sign_in board_member
      patch property_membership_path(property, membership), params: { membership: { role: "tenant" } }
      expect(response).to redirect_to(property_path(property))
      expect(membership.reload.role).to eq("tenant")
    end

    it "denies update for residents" do
      sign_in resident
      patch property_membership_path(property, membership), params: { membership: { role: "tenant" } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /properties/:property_id/memberships/:id" do
    let!(:membership) { create(:membership, property: property) }

    it "destroys for staff" do
      sign_in admin
      expect { delete property_membership_path(property, membership) }.to change(Membership, :count).by(-1)
      expect(response).to redirect_to(property_path(property))
    end

    it "denies deletion for residents" do
      sign_in resident
      delete property_membership_path(property, membership)
      expect(response).to redirect_to(root_path)
    end
  end
end
