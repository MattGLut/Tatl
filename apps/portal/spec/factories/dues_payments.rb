# frozen_string_literal: true

FactoryBot.define do
  factory :dues_payment do
    dues_assessment
    amount_cents { 25_000 }
    paid_on { Date.current }
    reference { "CHK-1234" }
  end
end
