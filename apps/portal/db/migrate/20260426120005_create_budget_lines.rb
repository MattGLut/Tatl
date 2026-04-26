# frozen_string_literal: true

class CreateBudgetLines < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_lines do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :fiscal_year, null: false
      t.integer :amount_cents, null: false, default: 0
      t.string :amount_currency, null: false, default: "USD"
      t.string :description

      t.timestamps
    end

    add_index :budget_lines, %i[account_id fiscal_year], unique: true
  end
end
