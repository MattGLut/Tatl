# frozen_string_literal: true

class TicketComment < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :ticket
  belongs_to :user

  has_one_attached :file

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :broadcast_new_comment

  private

  def broadcast_new_comment
    broadcast_append_to ticket,
      target: dom_id(ticket, :comments),
      partial: "tickets/tickets/comment",
      locals: { comment: self }
  end
end
