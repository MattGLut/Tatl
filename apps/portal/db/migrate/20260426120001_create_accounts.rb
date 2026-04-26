# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :account_type, null: false, default: 0
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :accounts, :account_type
    add_index :accounts, :active
  end
end
