# frozen_string_literal: true

module Accounting
  class BudgetLinePolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def create?
      user&.treasurer? || user&.admin?
    end

    def update?
      user&.treasurer? || user&.admin?
    end

    def destroy?
      admin?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.board? || user.treasurer?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end
