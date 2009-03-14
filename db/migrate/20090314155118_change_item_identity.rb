class ChangeItemIdentity < ActiveRecord::Migration
  def self.up
    #remove_index :items, [:feed_id, :link]
    add_index :items, [:feed_id, :parsed_at, :title]
  end

  def self.down
    add_index :items, [:feed_id, :link]
    remove_index :items, [:feed_id, :parsed_at, :title]
  end
end
