# frozen_string_literal: true

class TicketComment < ApplicationRecord
  belongs_to :ticket
  belongs_to :user

  has_one_attached :file

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }
end
