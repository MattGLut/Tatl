# frozen_string_literal: true

module PagyHelpers
  # Temporarily override Pagy's default page size for the duration of the block.
  # Used by request specs that need to exercise pagination without creating
  # tens of records per example.
  def with_pagy_limit(limit)
    original = Pagy::OPTIONS[:limit]
    Pagy::OPTIONS[:limit] = limit
    yield
  ensure
    Pagy::OPTIONS[:limit] = original
  end
end

RSpec.configure do |config|
  config.include PagyHelpers, type: :request
end
