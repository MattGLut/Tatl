# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    sequence(:subject) { |n| "Ticket #{n}" }
    description { "A test ticket description." }
    category { :maintenance }
    priority { :normal }
    status { :open }
    user

    trait :landscaping do
      category { :landscaping }
    end

    trait :noise_complaint do
      category { :noise_complaint }
    end

    trait :parking do
      category { :parking }
    end

    trait :suggestion do
      category { :suggestion }
      priority { :low }
    end

    trait :dues_question do
      category { :dues_question }
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :resolved do
      status { :resolved }
    end

    trait :closed do
      status { :closed }
      closed_at { Time.current }
    end

    trait :high_priority do
      priority { :high }
    end

    trait :urgent do
      priority { :urgent }
    end

    trait :with_property do
      property
    end
  end
end
