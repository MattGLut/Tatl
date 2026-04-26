# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
  has_many :budget_lines, dependent: :destroy

  enum :account_type, {
    operating: 0,
    reserve: 1,
    income: 2,
    expense: 3
  }, validate: true

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(account_type: type) }
end
