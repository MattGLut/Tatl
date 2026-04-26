# frozen_string_literal: true

module Accounting
  class ReportsController < ApplicationController
    before_action :authenticate_user!

    def summary
      authorize :report, :summary?, policy_class: Accounting::ReportPolicy
      @start_date = params[:start_date]&.to_date || Date.current.beginning_of_year
      @end_date = params[:end_date]&.to_date || Date.current
      @transactions = Transaction.includes(:account).in_period(@start_date, @end_date)

      @income_by_month = @transactions.joins(:account)
                                      .where(accounts: { account_type: %i[income operating] })
                                      .where("amount_cents > 0")
                                      .group_by_month(:transacted_on)
                                      .sum(:amount_cents)
                                      .transform_values { |v| v / 100.0 }

      @expense_by_month = @transactions.joins(:account)
                                       .where(accounts: { account_type: :expense })
                                       .or(
                                         @transactions.joins(:account)
                                                      .where("amount_cents < 0")
                                       )
                                       .group_by_month(:transacted_on)
                                       .sum("ABS(amount_cents)")
                                       .transform_values { |v| v / 100.0 }
    end

    def dues_aging
      authorize :report, :dues_aging?, policy_class: Accounting::ReportPolicy
      assessments = policy_scope(DuesAssessment, policy_scope_class: Accounting::DuesAssessmentPolicy::Scope)
                    .open_or_partial.or(
                      policy_scope(DuesAssessment, policy_scope_class: Accounting::DuesAssessmentPolicy::Scope).overdue
                    )
                    .includes(:property, :dues_payments)

      @aging_buckets = { current: [], "30_days": [], "60_days": [], "90_plus": [] }
      today = Date.current

      assessments.find_each do |a|
        days_past = (today - a.due_date).to_i
        paid = a.dues_payments.sum(:amount_cents)
        balance_cents = a.amount_cents - paid
        next if balance_cents <= 0

        entry = { assessment: a, balance: Money.new(balance_cents, "USD") }
        bucket = if days_past <= 0
                   :current
                 elsif days_past <= 30
                   :"30_days"
                 elsif days_past <= 60
                   :"60_days"
                 else
                   :"90_plus"
                 end
        @aging_buckets[bucket] << entry
      end
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
  end
end
