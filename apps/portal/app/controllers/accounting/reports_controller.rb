# frozen_string_literal: true

module Accounting
  class ReportsController < ApplicationController
    before_action :authenticate_user!

    def summary
      authorize :report, :summary?, policy_class: Accounting::ReportPolicy
      @start_date = params[:start_date]&.to_date || Date.current.beginning_of_year
      @end_date = params[:end_date]&.to_date || Date.current
      @transactions = Transaction.includes(:account).in_period(@start_date, @end_date)
      @income_by_month = monthly_totals_for(:income)
      @expense_by_month = monthly_totals_for(:expense)
    end

    def dues_aging
      authorize :report, :dues_aging?, policy_class: Accounting::ReportPolicy
      assessments = outstanding_assessments
      @aging_buckets = build_aging_buckets(assessments)
    end

    def reserve_balance
      authorize :report, :reserve_balance?, policy_class: Accounting::ReportPolicy
      reserve_accounts = Account.by_type(:reserve)

      @reserve_over_time = Transaction.where(account: reserve_accounts)
                                      .group_by_month(:transacted_on)
                                      .sum(:amount_cents)
                                      .transform_values { |v| v / 100.0 }

      @current_reserve = Money.new(
        Transaction.where(account: reserve_accounts).sum(:amount_cents), "USD"
      )
    end

    private

    def monthly_totals_for(type)
      scope = @transactions.joins(:account)

      scope = if type == :income
                scope.where(accounts: { account_type: %i[income operating] })
                     .where("amount_cents > 0")
              else
                scope.where(accounts: { account_type: :expense })
                     .or(scope.where("amount_cents < 0"))
              end

      scope.group_by_month(:transacted_on)
           .sum(type == :expense ? "ABS(amount_cents)" : :amount_cents)
           .transform_values { |v| v / 100.0 }
    end

    def outstanding_assessments
      base = policy_scope(DuesAssessment, policy_scope_class: Accounting::DuesAssessmentPolicy::Scope)
      base.open_or_partial
          .or(base.overdue)
          .includes(:property, :dues_payments)
    end

    def build_aging_buckets(assessments)
      buckets = { current: [], "30_days": [], "60_days": [], "90_plus": [] }

      assessments.find_each do |assessment|
        balance_cents = assessment.amount_cents - assessment.dues_payments.sum(:amount_cents)
        next if balance_cents <= 0

        entry = { assessment: assessment, balance: Money.new(balance_cents, "USD") }
        buckets[aging_bucket_for(assessment.due_date)] << entry
      end

      buckets
    end

    def aging_bucket_for(due_date)
      days_past = (Date.current - due_date).to_i
      return :current if days_past <= 0
      return :"30_days" if days_past <= 30
      return :"60_days" if days_past <= 60

      :"90_plus"
    end
  end
end
