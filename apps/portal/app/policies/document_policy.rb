# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (staff? || record.published?)
  end

  def create?
    staff?
  end

  def destroy?
    staff?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.board? || user.treasurer?
        scope.all
      else
        scope.published
      end
    end
  end
end
