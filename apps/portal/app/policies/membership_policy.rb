# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  def create?
    staff?
  end

  def update?
    staff?
  end

  def destroy?
    staff?
  end
end
