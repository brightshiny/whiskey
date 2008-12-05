class AddColumnsToFeedUsers < ActiveRecord::Migration

  def self.up
    add_column :feed_users, :feed_id, :integer, :null => false
    add_column :feed_users, :user_id, :integer, :null => false
    add_index :feed_users, [ :user_id, :feed_id ], :unique => true
  end

  def self.down
    remove_column :feed_users, :feed_id
    remove_column :feed_users, :user_id
  end

end
