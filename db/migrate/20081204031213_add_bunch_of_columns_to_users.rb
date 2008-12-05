class AddBunchOfColumnsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :login,                     :string, :limit => 40
    add_column :users, :name,                      :string, :limit => 100, :default => '', :null => true
    add_column :users, :email,                     :string, :limit => 100
    add_column :users, :crypted_password,          :string, :limit => 40
    add_column :users, :salt,                      :string, :limit => 40
    add_column :users, :remember_token,            :string, :limit => 40
    add_column :users, :remember_token_expires_at, :datetime
    add_index :users, :login, :unique => true
  end

  def self.down
    remove_column :users, :login
    remove_column :users, :name
    remove_column :users, :email
    remove_column :users, :crypted_password
    remove_column :users, :salt
    remove_column :users, :created_at
    remove_column :users, :updated_at
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
    remove_index :users, :login
  end
end
