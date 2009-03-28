class CreateItemUberMemes < ActiveRecord::Migration
  def self.up
    create_table :item_uber_memes do |t|
      t.integer  "item_id", :null => false
      t.integer  "run_id", :null => false
      t.integer  "uber_meme_id", :null => false
      t.decimal  "total_cosine_similarity", :precision => 10, :scale => 5
      t.decimal  "avg_cosine_similarity",   :precision => 10, :scale => 5
      t.timestamps
    end
    add_index :item_uber_memes, :item_id
    add_index :item_uber_memes, :run_id
    add_index :item_uber_memes, :uber_meme_id
  end

  def self.down
    drop_table :item_uber_memes
  end
end
