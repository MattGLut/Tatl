# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Rails.application.routes.default_url_options[:host] = "www.example.com"
    ActionMailer::Base.default_url_options[:host] = "www.example.com"
    ActionMailer::Base.deliveries.clear
  end
end
