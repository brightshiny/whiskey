class CreateItemRelationships < ActiveRecord::Migration
  def self.up
    create_table :item_relationships do |t|
      t.integer :item_id
      t.integer :related_item_id
      t.integer :run_id
      t.decimal :cosine_similarity, :precision => 10, :scale => 9
      t.timestamps
    end
  end

  def self.down
    drop_table :item_relationships
  end
end
