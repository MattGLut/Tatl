# frozen_string_literal: true

class AddTransactionLinksToDues < ActiveRecord::Migration[8.1]
  def change
    add_reference :dues_assessments, :transaction, null: true, foreign_key: true
    add_reference :dues_payments, :transaction, null: true, foreign_key: true
  end
end
