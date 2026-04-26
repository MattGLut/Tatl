# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::BudgetLines" do
  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:board_member) { create(:user, :board) }
  let(:resident) { create(:user) }
  let(:account) { create(:account) }

  describe "GET /accounting/budget_lines" do
    it "requires authentication" do
      get accounting_budget_lines_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists budget lines for staff" do
      create(:budget_line, account: account, description: "Landscaping")
      sign_in treasurer
      get accounting_budget_lines_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Landscaping")
    end

    it "denies access to residents" do
      sign_in resident
      get accounting_budget_lines_path
      expect(response).to redirect_to(root_path)
    end

    describe "sorting" do
      let!(:zeta) { create(:account, name: "Zeta Fund") }
      let!(:alpha) { create(:account, name: "Alpha Fund") }

      before do
        create(:budget_line, account: zeta, fiscal_year: Date.current.year, description: "Z line")
        create(:budget_line, account: alpha, fiscal_year: Date.current.year, description: "A line")
      end

      it "sorts by joined account name" do
        sign_in treasurer
        get accounting_budget_lines_path(sort: "account", dir: "asc")
        expect(response.body.index("Alpha Fund")).to be < response.body.index("Zeta Fund")
      end

      it "ignores unknown sort keys" do
        sign_in treasurer
        get accounting_budget_lines_path(sort: "evil")
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /accounting/budget_lines" do
    let(:valid_params) do
      { budget_line: { account_id: account.id, fiscal_year: 2026, amount: "500.00", description: "Insurance" } }
    end

    it "creates a budget line for treasurer" do
      sign_in treasurer
      expect { post accounting_budget_lines_path, params: valid_params }.to change(BudgetLine, :count).by(1)
      expect(response).to redirect_to(accounting_budget_lines_path(fiscal_year: 2026))
    end

    it "denies creation for board members" do
      sign_in board_member
      post accounting_budget_lines_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end

    it "denies creation for residents" do
      sign_in resident
      post accounting_budget_lines_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /accounting/budget_lines/:id" do
    let(:budget_line) { create(:budget_line) }

    it "updates for treasurer" do
      sign_in treasurer
      patch accounting_budget_line_path(budget_line), params: { budget_line: { description: "Updated" } }
      expect(response).to redirect_to(accounting_budget_lines_path(fiscal_year: budget_line.fiscal_year))
      expect(budget_line.reload.description).to eq("Updated")
    end
  end

  describe "DELETE /accounting/budget_lines/:id" do
    let!(:budget_line) { create(:budget_line) }

    it "deletes for admins" do
      sign_in admin
      expect { delete accounting_budget_line_path(budget_line) }.to change(BudgetLine, :count).by(-1)
    end

    it "denies deletion for treasurer" do
      sign_in treasurer
      delete accounting_budget_line_path(budget_line)
      expect(response).to redirect_to(root_path)
    end
  end
end
