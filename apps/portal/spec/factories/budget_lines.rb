# frozen_string_literal: true

FactoryBot.define do
  factory :budget_line do
    account
    fiscal_year { Date.current.year }
    amount_cents { 50_000 }
    description { "Annual budget allocation" }
  end
end
