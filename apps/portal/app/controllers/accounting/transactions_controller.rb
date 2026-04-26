# frozen_string_literal: true

module Accounting
  class TransactionsController < BaseController
    before_action :set_transaction, only: %i[show edit update destroy]

    def index
      authorize Transaction, :index?, policy_class: Accounting::TransactionPolicy
      @transactions = policy_scope(Transaction, policy_scope_class: Accounting::TransactionPolicy::Scope).recent
      @transactions = @transactions.for_account(params[:account_id]) if params[:account_id].present?
    end

    def show; end

    def new
      @transaction = authorize Transaction.new, policy_class: Accounting::TransactionPolicy
    end

    def edit; end

    def create
      @transaction = Transaction.new(transaction_params)
      @transaction.recorded_by = current_user
      authorize @transaction, policy_class: Accounting::TransactionPolicy

      if @transaction.save
        redirect_to accounting_transaction_path(@transaction), notice: "Transaction was successfully recorded."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @transaction.update(transaction_params)
        redirect_to accounting_transaction_path(@transaction), notice: "Transaction was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @transaction.destroy!
      redirect_to accounting_transactions_path, notice: "Transaction was successfully deleted.", status: :see_other
    end

    private

    def set_transaction
      @transaction = authorize Transaction.find(params[:id]), policy_class: Accounting::TransactionPolicy
    end

    def transaction_params
      params.expect(transaction: %i[transacted_on amount account_id memo file])
    end
  end
end
