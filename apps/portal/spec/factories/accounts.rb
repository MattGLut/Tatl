# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    account_type { :operating }
    active { true }

    trait :reserve do
      account_type { :reserve }
    end

    trait :income do
      account_type { :income }
    end

    trait :expense do
      account_type { :expense }
    end

    trait :inactive do
      active { false }
    end
  end
end
