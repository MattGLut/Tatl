# frozen_string_literal: true

module Accounting
  class DuesAssessmentPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present? && (staff? || owns_property?)
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
        if user.admin? || user.board? || user.treasurer?
          scope.all
        else
          scope.joins(property: :memberships)
               .where(memberships: { user_id: user.id, ended_on: nil })
               .distinct
        end
      end
    end

    private

    def owns_property?
      record.property.memberships.active.exists?(user_id: user.id)
    end
  end
end
