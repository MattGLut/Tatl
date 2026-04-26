# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_comment do
    body { "A test comment." }
    ticket
    user

    trait :with_file do
      after(:build) do |comment|
        comment.file.attach(
          io: StringIO.new("sample file content"),
          filename: "attachment.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
