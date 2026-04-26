# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::DuesPayments" do
  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:resident) { create(:user) }
  let(:assessment) { create(:dues_assessment, amount_cents: 25_000) }

  describe "GET /accounting/dues/:dues_assessment_id/payments/new" do
    it "renders the payment form for staff" do
      sign_in treasurer
      get new_accounting_dues_assessment_payment_path(assessment)
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get new_accounting_dues_assessment_payment_path(assessment)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /accounting/dues/:dues_assessment_id/payments" do
    let(:valid_params) { { dues_payment: { amount: "250.00", paid_on: Date.current, reference: "CHK-100" } } }

    it "creates a payment and recalculates assessment for staff" do
      sign_in treasurer
      expect do
        post accounting_dues_assessment_payments_path(assessment), params: valid_params
      end.to change(DuesPayment, :count).by(1)
      expect(response).to redirect_to(accounting_dues_assessment_path(assessment))
      expect(assessment.reload.status).to eq("paid")
    end

    it "denies creation for residents" do
      sign_in resident
      post accounting_dues_assessment_payments_path(assessment), params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /accounting/dues/:dues_assessment_id/payments/:id" do
    let!(:payment) { create(:dues_payment, dues_assessment: assessment) }

    it "removes a payment for admins" do
      sign_in admin
      expect do
        delete accounting_dues_assessment_payment_path(assessment, payment)
      end.to change(DuesPayment, :count).by(-1)
    end

    it "denies deletion for treasurer" do
      sign_in treasurer
      delete accounting_dues_assessment_payment_path(assessment, payment)
      expect(response).to redirect_to(root_path)
    end
  end
end
