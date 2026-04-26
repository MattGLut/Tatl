# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.date :transacted_on, null: false
      t.integer :amount_cents, null: false, default: 0
      t.string :amount_currency, null: false, default: "USD"
      t.text :memo
      t.references :account, null: false, foreign_key: true
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :transactions, :transacted_on
  end
end
