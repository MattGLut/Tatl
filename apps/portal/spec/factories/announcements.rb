# frozen_string_literal: true

FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "Community Update #{n}" }
    body { "Pool maintenance is scheduled this week." }
    active { true }
    pinned_until { 1.week.from_now }

    trait :inactive do
      active { false }
    end

    trait :expired do
      pinned_until { 1.day.ago }
    end

    trait :unpinned do
      pinned_until { nil }
    end
  end
end
