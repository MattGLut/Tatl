# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::Transactions" do
  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:board_member) { create(:user, :board) }
  let(:resident) { create(:user) }
  let(:account) { create(:account) }

  describe "GET /accounting/transactions" do
    it "requires authentication" do
      get accounting_transactions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists transactions for staff" do
      create(:transaction, memo: "Dues collected")
      sign_in treasurer
      get accounting_transactions_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dues collected")
    end

    it "denies access to residents" do
      sign_in resident
      get accounting_transactions_path
      expect(response).to redirect_to(root_path)
    end

    describe "sorting" do
      it "sorts by memo asc" do
        create(:transaction, memo: "Zebra")
        create(:transaction, memo: "Apple")

        sign_in treasurer
        get accounting_transactions_path(sort: "memo", dir: "asc")
        expect(response.body.index("Apple")).to be < response.body.index("Zebra")
      end

      it "ignores unknown sort keys" do
        sign_in treasurer
        get accounting_transactions_path(sort: "drop_table")
        expect(response).to have_http_status(:ok)
      end
    end

    describe "pagination" do
      around { |ex| with_pagy_limit(3) { ex.run } }

      it "limits results to one page" do
        create_list(:transaction, 5)
        sign_in treasurer
        get accounting_transactions_path
        # 3 body rows + 1 thead row
        expect(response.body.scan("<tr>").size).to eq(4)
      end

      it "renders subsequent pages" do
        create_list(:transaction, 5)
        sign_in treasurer
        get accounting_transactions_path(page: 2)
        # 2 remaining body rows + 1 thead row
        expect(response.body.scan("<tr>").size).to eq(3)
      end
    end
  end

  describe "GET /accounting/transactions/:id" do
    let(:txn) { create(:transaction) }

    it "shows transaction details to staff" do
      sign_in board_member
      get accounting_transaction_path(txn)
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get accounting_transaction_path(txn)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /accounting/transactions" do
    let(:valid_params) do
      { transaction: { transacted_on: Date.current, amount: "100.00", account_id: account.id, memo: "Test" } }
    end

    it "creates a transaction for treasurer" do
      sign_in treasurer
      expect { post accounting_transactions_path, params: valid_params }.to change(Transaction, :count).by(1)
      expect(Transaction.last.recorded_by).to eq(treasurer)
      expect(response).to redirect_to(accounting_transaction_path(Transaction.last))
    end

    it "denies creation for board members" do
      sign_in board_member
      post accounting_transactions_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end

    it "denies creation for residents" do
      sign_in resident
      post accounting_transactions_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /accounting/transactions/:id" do
    let!(:txn) { create(:transaction) }

    it "deletes for admins" do
      sign_in admin
      expect { delete accounting_transaction_path(txn) }.to change(Transaction, :count).by(-1)
    end

    it "denies deletion for treasurer" do
      sign_in treasurer
      delete accounting_transaction_path(txn)
      expect(response).to redirect_to(root_path)
    end
  end
end
