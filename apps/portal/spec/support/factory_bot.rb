# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    if ENV["FACTORY_BOT_LINT"] == "1"
      begin
        FactoryBot.lint(traits: true)
      rescue FactoryBot::InvalidFactoryError => e
        raise "FactoryBot lint failed: #{e.message}"
      end
    end
  end
end
