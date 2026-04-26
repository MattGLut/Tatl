# frozen_string_literal: true

module Accounting
  class AccountPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present?
    end

    def create?
      staff?
    end

    def update?
      staff?
    end

    def destroy?
      admin?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.all
      end
    end
  end
end
