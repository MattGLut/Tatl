# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    transacted_on { Date.current }
    amount_cents { 10_000 }
    memo { "Monthly dues collection" }
    account
    recorded_by factory: %i[user treasurer]

    trait :expense do
      amount_cents { -5_000 }
      memo { "Landscaping payment" }
    end

    trait :large do
      amount_cents { 100_000 }
    end
  end
end
