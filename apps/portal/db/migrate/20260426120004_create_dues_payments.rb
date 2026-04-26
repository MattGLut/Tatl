# frozen_string_literal: true

class CreateDuesPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :dues_payments do |t|
      t.references :dues_assessment, null: false, foreign_key: true
      t.integer :amount_cents, null: false, default: 0
      t.string :amount_currency, null: false, default: "USD"
      t.date :paid_on, null: false
      t.string :reference

      t.timestamps
    end

    add_index :dues_payments, :paid_on
  end
end
