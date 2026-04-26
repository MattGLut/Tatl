# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :recorded_by, class_name: "User"

  has_one_attached :file

  monetize :amount_cents

  validates :transacted_on, presence: true
  validates :amount_cents, numericality: { other_than: 0 }

  scope :recent, -> { order(transacted_on: :desc, created_at: :desc) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :in_period, ->(start_date, end_date) { where(transacted_on: start_date..end_date) }
end
