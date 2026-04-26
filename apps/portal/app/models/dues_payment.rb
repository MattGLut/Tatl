# frozen_string_literal: true

class DuesPayment < ApplicationRecord
  belongs_to :dues_assessment
  belongs_to :ledger_transaction, class_name: "Transaction", foreign_key: :transaction_id,
                                   inverse_of: false, optional: true

  monetize :amount_cents

  validates :paid_on, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }

  after_create :recalculate_assessment_status
  after_destroy :recalculate_assessment_status

  private

  def recalculate_assessment_status
    dues_assessment.recalculate_status!
  end
end
