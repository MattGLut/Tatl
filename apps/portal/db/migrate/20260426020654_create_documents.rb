# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.text :description
      t.integer :category, null: false, default: 0
      t.datetime :published_at
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.integer :rag_sync_status, null: false, default: 0
      t.datetime :last_indexed_at

      t.timestamps
    end

    add_index :documents, :category
    add_index :documents, :rag_sync_status
    add_index :documents, :published_at
  end
end
