# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.date :started_on, null: false
      t.date :ended_on

      t.timestamps
    end

    add_index :memberships, %i[user_id property_id ended_on],
              unique: true,
              name: "index_memberships_active_unique"
  end
end
