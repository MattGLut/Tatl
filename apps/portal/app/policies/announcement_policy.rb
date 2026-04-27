# frozen_string_literal: true

class AnnouncementPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless admin?

      scope.order(created_at: :desc)
    end

    private

    def admin?
      user&.admin?
    end
  end
end
