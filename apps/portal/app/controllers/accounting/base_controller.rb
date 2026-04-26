# frozen_string_literal: true

module Accounting
  class BaseController < ApplicationController
    before_action :authenticate_user!

    after_action :verify_authorized
  end
end
