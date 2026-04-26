# frozen_string_literal: true

module Accounting
  class AccountsController < BaseController
    after_action :verify_policy_scoped, only: :index
    before_action :set_account, only: %i[show edit update destroy]

    def index
      authorize Account, :index?, policy_class: Accounting::AccountPolicy
      @accounts = policy_scope(Account, policy_scope_class: Accounting::AccountPolicy::Scope).order(:name)
    end

    def show; end

    def new
      @account = authorize Account.new, policy_class: Accounting::AccountPolicy
    end

    def edit; end

    def create
      @account = Account.new(account_params)
      authorize @account, policy_class: Accounting::AccountPolicy

      if @account.save
        redirect_to accounting_account_path(@account), notice: "Account was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @account.update(account_params)
        redirect_to accounting_account_path(@account), notice: "Account was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @account.destroy!
      redirect_to accounting_accounts_path, notice: "Account was successfully deleted.", status: :see_other
    end

    private

    def set_account
      @account = authorize Account.find(params[:id]), policy_class: Accounting::AccountPolicy
    end

    def account_params
      params.expect(account: %i[name account_type description active])
    end
  end
end
