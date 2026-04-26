# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (staff? || user_has_membership?)
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
        scope.joins(:memberships).where(memberships: { user_id: user.id, ended_on: nil }).distinct
      end
    end
  end

  private

  def user_has_membership?
    record.memberships.active.exists?(user_id: user.id)
  end
end
