# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :uploaded_by, class_name: "User", inverse_of: :uploaded_documents

  has_one_attached :file

  enum :category, {
    policy: 0,
    bylaws: 1,
    minutes: 2,
    financial_report: 3,
    form: 4,
    other: 5
  }, validate: true

  enum :rag_sync_status, {
    pending: 0,
    indexed: 1,
    failed: 2
  }, default: :pending, prefix: :rag, validate: true

  validates :title, presence: true
  validates :file, presence: true, on: :create

  scope :published, -> { where.not(published_at: nil) }
  scope :drafts, -> { where(published_at: nil) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :recent, -> { order(created_at: :desc) }

  def published?
    published_at.present?
  end
end
