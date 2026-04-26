# frozen_string_literal: true

class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true

  has_many :ticket_comments, dependent: :destroy

  enum :category, {
    maintenance: 0,
    landscaping: 1,
    noise_complaint: 2,
    parking: 3,
    common_area: 4,
    dues_question: 5,
    suggestion: 6,
    other: 7
  }, validate: true

  enum :priority, {
    low: 0,
    normal: 1,
    high: 2,
    urgent: 3
  }, default: :normal, validate: true

  enum :status, {
    open: 0,
    in_progress: 1,
    resolved: 2,
    closed: 3
  }, default: :open, validate: true

  validates :subject, presence: true
  validates :description, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(s) { where(status: s) }
  scope :by_category, ->(c) { where(category: c) }
  scope :by_priority, ->(p) { where(priority: p) }
  scope :active, -> { where(status: %i[open in_progress]) }

  def close!
    update!(status: :closed, closed_at: Time.current)
  end

  def reopen!
    update!(status: :open, closed_at: nil)
  end
end
