# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "resident#{n}@tatl.example" }
    password { "Tatl-Password-1!" }
    password_confirmation { "Tatl-Password-1!" }
    first_name { "Test" }
    last_name { "Resident" }
    role { :resident }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :board do
      role { :board }
    end

    trait :treasurer do
      role { :treasurer }
    end

    trait :admin do
      role { :admin }
    end

    trait :locked do
      locked_at { Time.current }
      failed_attempts { 10 }
    end
  end
end
