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

    it "filters by account_id" do
      a1 = create(:account, name: "Op Account")
      a2 = create(:account, name: "Other Account")
      create(:transaction, account: a1, memo: "First memo")
      create(:transaction, account: a2, memo: "Second memo")

      sign_in treasurer
      get accounting_transactions_path(account_id: a1.id)
      expect(response.body).to include("First memo")
      expect(response.body).not_to include("Second memo")
    end

    it "filters by transacted date range" do
      create(:transaction, transacted_on: Date.new(2026, 4, 1), memo: "In range")
      create(:transaction, transacted_on: Date.new(2026, 1, 1), memo: "Too early")
      sign_in treasurer
      get accounting_transactions_path(transacted_on_start: "2026-03-15", transacted_on_end: "2026-04-15")
      expect(response.body).to include("In range")
      expect(response.body).not_to include("Too early")
    end

    it "filters from transacted_on_start when end is open" do
      create(:transaction, transacted_on: Date.new(2026, 5, 1), memo: "After cutoff")
      create(:transaction, transacted_on: Date.new(2025, 1, 1), memo: "Before cutoff")
      sign_in treasurer
      get accounting_transactions_path(transacted_on_start: "2026-01-01")
      expect(response.body).to include("After cutoff")
      expect(response.body).not_to include("Before cutoff")
    end

    it "ignores invalid transacted date params" do
      create(:transaction, memo: "Solo line")
      sign_in treasurer
      get accounting_transactions_path(
        transacted_on_start: "nope",
        transacted_on_end: "x"
      )
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Solo line")
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

      it "keeps account and date in pagination next link" do
        acct = create(:account, name: "Pagy Acct")
        d = "2020-01-15"
        with_pagy_limit(1) do
          create_list(:transaction, 2, account: acct)
          sign_in treasurer
          get accounting_transactions_path(
            account_id: acct.id, transacted_on_start: d, transacted_on_end: "2030-12-31"
          )
        end
        expect(response.body).to include("Next", "account_id=", "transacted_on_start=")
        expect(response.body).to include(acct.id.to_s)
      end
    end
  end

  describe "GET /accounting/transactions/new" do
    it "renders the form for treasurer" do
      sign_in treasurer
      get new_accounting_transaction_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to board members" do
      sign_in board_member
      get new_accounting_transaction_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /accounting/transactions/:id/edit" do
    let(:txn) { create(:transaction, memo: "Original memo") }

    it "renders the form for treasurer" do
      sign_in treasurer
      get edit_accounting_transaction_path(txn)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Original memo")
    end

    it "denies access to board members" do
      sign_in board_member
      get edit_accounting_transaction_path(txn)
      expect(response).to redirect_to(root_path)
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

  describe "PATCH /accounting/transactions/:id" do
    let(:txn) { create(:transaction, memo: "Before", account: account) }
    let(:update_params) do
      {
        transaction: {
          transacted_on: txn.transacted_on,
          amount: "200.00",
          account_id: account.id,
          memo: "After update"
        }
      }
    end

    it "updates for treasurer" do
      sign_in treasurer
      patch accounting_transaction_path(txn), params: update_params
      expect(response).to redirect_to(accounting_transaction_path(txn))
      expect(txn.reload.memo).to eq("After update")
      expect(txn.amount_cents).to eq(20_000)
    end

    it "denies update for board members" do
      sign_in board_member
      patch accounting_transaction_path(txn), params: update_params
      expect(response).to redirect_to(root_path)
      expect(txn.reload.memo).to eq("Before")
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
