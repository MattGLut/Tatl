# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::DuesAssessments" do
  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:resident) { create(:user) }
  let(:property) { create(:property) }

  describe "GET /accounting/dues" do
    it "requires authentication" do
      get accounting_dues_assessments_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists all assessments for staff" do
      create(:dues_assessment, property: property)
      sign_in treasurer
      get accounting_dues_assessments_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(property.name)
    end

    it "lists only own-property assessments for residents" do
      own_prop = create(:property, name: "My Lot")
      other_prop = create(:property, name: "Other Lot")
      create(:membership, user: resident, property: own_prop)
      create(:dues_assessment, property: own_prop)
      create(:dues_assessment, property: other_prop)

      sign_in resident
      get accounting_dues_assessments_path
      expect(response.body).to include("My Lot")
      expect(response.body).not_to include("Other Lot")
    end
  end

  describe "GET /accounting/dues/:id" do
    let(:assessment) { create(:dues_assessment, property: property) }

    it "shows details to staff" do
      sign_in admin
      get accounting_dues_assessment_path(assessment)
      expect(response).to have_http_status(:ok)
    end

    it "shows details to resident with membership" do
      create(:membership, user: resident, property: property)
      sign_in resident
      get accounting_dues_assessment_path(assessment)
      expect(response).to have_http_status(:ok)
    end

    it "denies access to resident without membership" do
      sign_in resident
      get accounting_dues_assessment_path(assessment)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /accounting/dues" do
    let(:valid_params) do
      {
        dues_assessment: {
          property_id: property.id, amount: "250.00",
          period_start: Date.current.beginning_of_quarter,
          period_end: Date.current.end_of_quarter,
          due_date: Date.current + 30, description: "Q2 Dues"
        }
      }
    end

    it "creates an assessment for staff" do
      sign_in treasurer
      expect { post accounting_dues_assessments_path, params: valid_params }.to change(DuesAssessment, :count).by(1)
      expect(response).to redirect_to(accounting_dues_assessment_path(DuesAssessment.last))
    end

    it "denies creation for residents" do
      sign_in resident
      post accounting_dues_assessments_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /accounting/dues/:id" do
    let!(:assessment) { create(:dues_assessment) }

    it "deletes for admins" do
      sign_in admin
      expect { delete accounting_dues_assessment_path(assessment) }.to change(DuesAssessment, :count).by(-1)
    end

    it "denies deletion for treasurer" do
      sign_in treasurer
      delete accounting_dues_assessment_path(assessment)
      expect(response).to redirect_to(root_path)
    end
  end
end
