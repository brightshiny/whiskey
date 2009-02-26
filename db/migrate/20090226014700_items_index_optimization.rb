class ItemsIndexOptimization < ActiveRecord::Migration
  def self.up
    remove_index :items, [ :feed_id, :published_at ]
    add_index :items, :published_at
  end
  
  def self.down
    add_index :items, [ :feed_id, :published_at ]
    remove_index :items, :published_at
  end
end
