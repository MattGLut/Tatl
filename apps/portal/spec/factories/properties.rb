# frozen_string_literal: true

FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Unit #{n}" }
    street_address { "123 Oak Street" }
    city { "Nashville" }
    state { "TN" }
    zip { "37201" }
    sequence(:lot_number) { |n| "LOT-#{n.to_s.rjust(4, "0")}" }
    property_type { :single_family }

    trait :townhome do
      property_type { :townhome }
    end

    trait :condo do
      property_type { :condo }
    end

    trait :lot do
      property_type { :lot }
      street_address { nil }
    end
  end
end
