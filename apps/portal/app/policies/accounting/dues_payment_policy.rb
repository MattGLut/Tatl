# frozen_string_literal: true

module Accounting
  class DuesPaymentPolicy < ApplicationPolicy
    def create?
      staff?
    end

    def destroy?
      admin?
    end
  end
end
