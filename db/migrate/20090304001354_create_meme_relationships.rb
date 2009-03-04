class CreateMemeRelationships < ActiveRecord::Migration
  def self.up
    create_table :meme_relationships do |t|
      t.integer :meme_comparison_id
      t.integer :meme_id
      t.integer :related_meme_id
    end
    add_index :meme_relationships, :meme_comparison_id
    add_index :meme_relationships, :meme_id
    add_index :meme_relationships, :related_meme_id
  end

  def self.down
    drop_table :meme_relationships
  end
end
