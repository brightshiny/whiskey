class AddIndexToMemeItems < ActiveRecord::Migration
  def self.up
    add_index :meme_items, :meme_id
    add_index :meme_items, :item_relationship_id
  end

  def self.down
    remove_index :meme_items, :meme_id
    remove_index :meme_items, :item_relationship_id
  end
end
