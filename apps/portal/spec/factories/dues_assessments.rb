# frozen_string_literal: true

FactoryBot.define do
  factory :dues_assessment do
    property
    amount_cents { 25_000 }
    period_start { Date.current.beginning_of_quarter }
    period_end { Date.current.end_of_quarter }
    due_date { Date.current.beginning_of_quarter + 30.days }
    description { "Q#{((Date.current.month - 1) / 3) + 1} HOA Dues" }
    status { :open }

    trait :overdue do
      due_date { 60.days.ago.to_date }
      status { :overdue }
    end

    trait :partial do
      status { :partial }
    end

    trait :paid do
      status { :paid }
    end
  end
end
