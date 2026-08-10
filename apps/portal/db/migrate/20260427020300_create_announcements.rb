# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :active, null: false, default: true
      t.datetime :pinned_until

      t.timestamps
    end

    add_index :announcements, :active
    add_index :announcements, :pinned_until
  end
end
