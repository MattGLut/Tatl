# frozen_string_literal: true

class AddUniqueIndexOnAccountsName < ActiveRecord::Migration[8.1]
  def change
    add_index :accounts, :name, unique: true
  end
end
