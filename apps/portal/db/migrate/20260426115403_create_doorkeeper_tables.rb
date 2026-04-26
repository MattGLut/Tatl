# frozen_string_literal: true

class CreateDoorkeeperTables < ActiveRecord::Migration[8.1]
  def change
    create_oauth_applications
    create_oauth_access_grants
    create_oauth_access_tokens
    add_resource_owner_foreign_keys
  end

  private

  def create_oauth_applications
    create_table :oauth_applications do |t|
      t.string  :name,    null: false
      t.string  :uid,     null: false
      t.string  :secret,  null: false
      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ""
      t.boolean :confidential, null: false, default: true
      t.timestamps             null: false
    end

    add_index :oauth_applications, :uid, unique: true
  end

  def create_oauth_access_grants
    create_table :oauth_access_grants do |t|
      t.references :resource_owner,  null: false
      t.references :application,     null: false
      t.string   :token,             null: false
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.string   :scopes,            null: false, default: ""
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
    end

    add_index :oauth_access_grants, :token, unique: true
    add_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id
  end

  def create_oauth_access_tokens
    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, index: true
      t.references :application,    null: false
      t.string :token, null: false
      t.string   :refresh_token
      t.integer  :expires_in
      t.string   :scopes
      t.datetime :created_at, null: false
      t.datetime :revoked_at
      t.string   :previous_refresh_token, null: false, default: ""
    end

    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true
    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id
  end

  def add_resource_owner_foreign_keys
    add_foreign_key :oauth_access_grants, :users, column: :resource_owner_id
    add_foreign_key :oauth_access_tokens, :users, column: :resource_owner_id
  end
end
