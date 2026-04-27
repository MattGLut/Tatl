# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::Reports" do
  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:resident) { create(:user) }

  describe "GET /accounting/reports/summary" do
    it "requires authentication" do
      get accounting_reports_summary_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders for staff" do
      sign_in treasurer
      get accounting_reports_summary_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Financial Summary")
    end

    it "denies access to residents" do
      sign_in resident
      get accounting_reports_summary_path
      expect(response).to redirect_to(root_path)
    end

    it "honors start_date and end_date query params" do
      sign_in treasurer
      get accounting_reports_summary_path(start_date: "2026-04-01", end_date: "2026-04-30")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apr 01, 2026")
      expect(response.body).to include("Apr 30, 2026")
    end
  end

  describe "GET /accounting/reports/dues_aging" do
    it "renders for any signed-in user" do
      sign_in resident
      get accounting_reports_dues_aging_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dues Aging")
    end

    it "renders for staff" do
      sign_in admin
      get accounting_reports_dues_aging_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /accounting/reports/reserve_balance" do
    it "renders for staff" do
      sign_in treasurer
      get accounting_reports_reserve_balance_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reserve Fund")
    end

    it "denies access to residents" do
      sign_in resident
      get accounting_reports_reserve_balance_path
      expect(response).to redirect_to(root_path)
    end
  end
end
