class RemoveCookieUserIdIndex < ActiveRecord::Migration
  def self.up
    remove_index :clicks, :cookie_user_id;
  end

  def self.down
    add_index :clicks, :cookie_user_id;
  end
end
