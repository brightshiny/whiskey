class CreateUberMemeItems < ActiveRecord::Migration
  def self.up
    create_table :uber_meme_items do |t|
      t.integer  "item_id", :null => false
      t.integer  "run_id", :null => false
      t.integer  "uber_meme_id", :null => false
      t.decimal  "total_cosine_similarity", :precision => 10, :scale => 5
      t.decimal  "avg_cosine_similarity",   :precision => 10, :scale => 5
      t.timestamps
    end
    add_index :uber_meme_items, :item_id
    add_index :uber_meme_items, :run_id
    add_index :uber_meme_items, :uber_meme_id
  end

  def self.down
    drop_table :uber_meme_items
  end
end
