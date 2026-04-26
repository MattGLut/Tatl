# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    sequence(:title) { |n| "Document #{n}" }
    description { "A test document." }
    category { :policy }
    published_at { Time.current }
    uploaded_by factory: %i[user]

    after(:build) do |doc|
      doc.file.attach(
        io: StringIO.new("sample file content"),
        filename: "test-document.pdf",
        content_type: "application/pdf"
      )
    end

    trait :draft do
      published_at { nil }
    end

    trait :bylaws do
      category { :bylaws }
    end

    trait :minutes do
      category { :minutes }
    end

    trait :financial_report do
      category { :financial_report }
    end

    trait :form do
      category { :form }
    end
  end
end
