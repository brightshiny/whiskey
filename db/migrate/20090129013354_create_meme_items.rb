class CreateMemeItems < ActiveRecord::Migration
  def self.up
    create_table :meme_items do |t|
      t.integer :meme_id
      t.integer :item_relationship_id
      t.timestamps
    end
  end
  
  def self.down
    drop_table :meme_items
  end
end
