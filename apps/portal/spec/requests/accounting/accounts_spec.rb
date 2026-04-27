# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::Accounts" do
  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:resident) { create(:user) }

  describe "GET /accounting/accounts" do
    it "requires authentication" do
      get accounting_accounts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists accounts for any signed-in user" do
      create(:account, name: "Operating Fund")
      sign_in resident
      get accounting_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Operating Fund")
    end

    describe "sorting" do
      it "sorts by name asc by default" do
        create(:account, name: "Zeta")
        create(:account, name: "Alpha")
        sign_in resident
        get accounting_accounts_path
        expect(response.body.index("Alpha")).to be < response.body.index("Zeta")
      end

      it "honors a desc sort param" do
        create(:account, name: "Zeta")
        create(:account, name: "Alpha")
        sign_in resident
        get accounting_accounts_path(sort: "name", dir: "desc")
        expect(response.body.index("Zeta")).to be < response.body.index("Alpha")
      end

      it "ignores unknown sort keys" do
        sign_in resident
        get accounting_accounts_path(sort: "boom")
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /accounting/accounts/:id" do
    let(:account) { create(:account) }

    it "shows account details to signed-in users" do
      sign_in resident
      get accounting_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.name)
    end
  end

  describe "GET /accounting/accounts/new" do
    it "renders the form for staff" do
      sign_in treasurer
      get new_accounting_account_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get new_accounting_account_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /accounting/accounts/:id/edit" do
    let(:account) { create(:account, name: "Editable Fund") }

    it "renders the form for staff" do
      sign_in treasurer
      get edit_accounting_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editable Fund")
    end

    it "denies access to residents" do
      sign_in resident
      get edit_accounting_account_path(account)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /accounting/accounts" do
    let(:valid_params) { { account: { name: "Reserve Fund", account_type: "reserve" } } }

    it "creates an account for staff" do
      sign_in admin
      expect { post accounting_accounts_path, params: valid_params }.to change(Account, :count).by(1)
      expect(response).to redirect_to(accounting_account_path(Account.last))
    end

    it "re-renders on invalid data" do
      sign_in admin
      post accounting_accounts_path, params: { account: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies creation for residents" do
      sign_in resident
      post accounting_accounts_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /accounting/accounts/:id" do
    let(:account) { create(:account) }

    it "updates for staff" do
      sign_in treasurer
      patch accounting_account_path(account), params: { account: { name: "Updated" } }
      expect(response).to redirect_to(accounting_account_path(account))
      expect(account.reload.name).to eq("Updated")
    end

    it "denies update for residents" do
      sign_in resident
      patch accounting_account_path(account), params: { account: { name: "Hacked" } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /accounting/accounts/:id" do
    let!(:account) { create(:account) }

    it "deletes for admins" do
      sign_in admin
      expect { delete accounting_account_path(account) }.to change(Account, :count).by(-1)
      expect(response).to redirect_to(accounting_accounts_path)
    end

    it "denies deletion for treasurer" do
      sign_in treasurer
      delete accounting_account_path(account)
      expect(response).to redirect_to(root_path)
    end

    it "denies deletion for residents" do
      sign_in resident
      delete accounting_account_path(account)
      expect(response).to redirect_to(root_path)
    end
  end
end
