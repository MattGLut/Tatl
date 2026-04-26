# frozen_string_literal: true

class CreateDuesAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :dues_assessments do |t|
      t.references :property, null: false, foreign_key: true
      t.integer :amount_cents, null: false, default: 0
      t.string :amount_currency, null: false, default: "USD"
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.date :due_date, null: false
      t.string :description
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :dues_assessments, :status
    add_index :dues_assessments, :due_date
  end
end
