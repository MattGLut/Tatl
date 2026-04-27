# frozen_string_literal: true

class AddAnnouncementEmailsEnabledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :announcement_emails_enabled, :boolean, null: false, default: true
  end
end
