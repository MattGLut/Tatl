# frozen_string_literal: true

module Accounting
  class TransactionsController < BaseController
    TRANSACTION_SORTS = {
      "transacted_on" => :transacted_on,
      "amount_cents" => :amount_cents,
      "memo" => :memo
    }.freeze

    after_action :verify_policy_scoped, only: :index
    before_action :set_transaction, only: %i[show edit update destroy]

    def index
      authorize Transaction, :index?, policy_class: Accounting::TransactionPolicy
      @filter_accounts = policy_scope(Account, policy_scope_class: Accounting::AccountPolicy::Scope).order(:name)
      scope = policy_scope(Transaction, policy_scope_class: Accounting::TransactionPolicy::Scope).includes(:account)
      scope = scope.for_account(transaction_account_id_param) if transaction_account_id_param
      scope = apply_transaction_date_filters(scope)
      scope = apply_sort(scope, allowed: TRANSACTION_SORTS, default: { transacted_on: :desc, created_at: :desc })
      @pagy, @transactions = pagy(scope)
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

    def transaction_account_id_param
      s = params[:account_id].to_s
      return unless s.match?(/\A[1-9]\d*\z/)

      s.to_i
    end

    def apply_transaction_date_filters(scope)
      start_d = date_from_param(:transacted_on_start)
      end_d = date_from_param(:transacted_on_end)
      if start_d && end_d
        lo, hi = [start_d, end_d].minmax
        scope = scope.in_period(lo, hi)
      elsif start_d
        scope = scope.transacted_on_or_after(start_d)
      elsif end_d
        scope = scope.transacted_on_or_before(end_d)
      end
      scope
    end
  end
end
