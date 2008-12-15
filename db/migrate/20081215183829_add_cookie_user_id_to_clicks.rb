class AddCookieUserIdToClicks < ActiveRecord::Migration
  def self.up
    add_column :clicks, :cookie_user_id, :integer
    add_index :clicks, :cookie_user_id
  end

  def self.down
    remove_index :clicks, :cookie_user_id
    remove_column :clicks, :cookie_user_id
  end
end
