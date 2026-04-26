# frozen_string_literal: true

class DuesAssessment < ApplicationRecord
  belongs_to :property
  belongs_to :ledger_transaction, class_name: "Transaction", foreign_key: :transaction_id,
                                  inverse_of: false, optional: true

  has_many :dues_payments, dependent: :destroy

  monetize :amount_cents

  enum :status, {
    open: 0,
    partial: 1,
    paid: 2,
    overdue: 3
  }, validate: true

  validates :period_start, :period_end, :due_date, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validate :period_end_after_start

  scope :open_or_partial, -> { where(status: %i[open partial]) }
  scope :overdue, -> { where(status: :overdue) }
  scope :for_property, ->(property_id) { where(property_id: property_id) }
  scope :for_fiscal_year, lambda { |year|
    where(period_start: Date.new(year, 1, 1)..Date.new(year, 12, 31))
  }
  scope :due_on_or_after, ->(date) { where("due_date >= ?", date) }
  scope :due_on_or_before, ->(date) { where("due_date <= ?", date) }

  def recalculate_status!
    total_paid = dues_payments.sum(:amount_cents)

    new_status = if total_paid >= amount_cents
                   :paid
                 elsif total_paid.positive?
                   :partial
                 elsif due_date < Date.current
                   :overdue
                 else
                   :open
                 end

    update!(status: new_status)
  end

  private

  def period_end_after_start
    return if period_start.blank? || period_end.blank?
    return if period_end > period_start

    errors.add(:period_end, "must be after period start")
  end
end
