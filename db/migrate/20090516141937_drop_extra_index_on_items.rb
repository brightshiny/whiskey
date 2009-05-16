class DropExtraIndexOnItems < ActiveRecord::Migration
  def self.up
    remove_index :items, [ :feed_id, :published_at ]
  end

  def self.down
    add_index :items, [ :feed_id, :published_at ]
  end
end
