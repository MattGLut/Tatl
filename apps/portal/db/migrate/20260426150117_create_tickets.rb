# frozen_string_literal: true

class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :subject, null: false
      t.text :description, null: false
      t.integer :category, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.references :user, null: false, foreign_key: true
      t.references :property, foreign_key: true
      t.datetime :closed_at

      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :category
    add_index :tickets, :priority
  end
end
