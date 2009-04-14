class RedoFeedUserIndexes < ActiveRecord::Migration
  def self.up
    add_index :feed_users, [ :feed_id, :user_id ], :unique => true
  end

  def self.down
    remove_index :feed_users, [ :feed_id, :user_id ], :unique => true
  end
end
