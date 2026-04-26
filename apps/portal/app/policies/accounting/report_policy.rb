# frozen_string_literal: true

module Accounting
  class ReportPolicy < ApplicationPolicy
    def summary?
      staff?
    end

    def dues_aging?
      user.present?
    end

    def reserve_balance?
      staff?
    end
  end
end
