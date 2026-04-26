# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    user
    property
    role { :owner }
    started_on { Date.current }
    ended_on { nil }

    trait :resident do
      role { :resident }
    end

    trait :tenant do
      role { :tenant }
    end

    trait :ended do
      ended_on { Date.current }
      started_on { 1.year.ago.to_date }
    end
  end
end
