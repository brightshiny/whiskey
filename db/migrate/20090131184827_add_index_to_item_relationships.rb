class AddIndexToItemRelationships < ActiveRecord::Migration
  def self.up
    add_index :item_relationships, :item_id
    add_index :item_relationships, :related_item_id
    add_index :item_relationships, :run_id
  end

  def self.down
    remove_index :item_relationships, :item_id
    remove_index :item_relationships, :related_item_id
    remove_index :item_relationships, :run_id
  end
end
