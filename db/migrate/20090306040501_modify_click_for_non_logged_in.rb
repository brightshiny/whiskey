class ModifyClickForNonLoggedIn < ActiveRecord::Migration
  def self.up
    change_column :clicks, :user_id, :integer, :null => true
    add_column :clicks, :session_id, :string, :length => 300, :null => true
  end

  def self.down
    add_column :clicks, :user_id, :integer, :null => false
    remove_column :clicks, :session_id
  end
end
