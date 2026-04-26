# frozen_string_literal: true

class BudgetLine < ApplicationRecord
  belongs_to :account

  monetize :amount_cents

  validates :fiscal_year, presence: true,
                          numericality: { only_integer: true, greater_than: 2000 }
  validates :account_id, uniqueness: { scope: :fiscal_year }

  scope :for_year, ->(year) { where(fiscal_year: year) }
end
