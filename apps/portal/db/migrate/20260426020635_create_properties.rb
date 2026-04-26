# frozen_string_literal: true

class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :street_address
      t.string :city
      t.string :state
      t.string :zip
      t.string :lot_number
      t.integer :property_type, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :properties, :lot_number, unique: true
    add_index :properties, :property_type
  end
end
