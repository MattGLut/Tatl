# frozen_string_literal: true

class TicketPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (staff? || record.user_id == user.id)
  end

  def create?
    user.present?
  end

  def update_status?
    staff?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.board? || user.treasurer?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
