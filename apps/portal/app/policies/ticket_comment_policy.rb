# frozen_string_literal: true

class TicketCommentPolicy < ApplicationPolicy
  def create?
    user.present? && (staff? || record.ticket.user_id == user.id)
  end
end
