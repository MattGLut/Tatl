# frozen_string_literal: true

class CreateTicketComments < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_comments do |t|
      t.text :body, null: false
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
