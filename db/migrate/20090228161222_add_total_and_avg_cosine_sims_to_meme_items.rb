class AddTotalAndAvgCosineSimsToMemeItems < ActiveRecord::Migration
  def self.up
   add_column :meme_items, :total_cosine_similarity, :decimal, :precision => 10, :scale => 5
   add_column :meme_items, :avg_cosine_similarity, :decimal, :precision => 10, :scale => 5
  end

  def self.down
   remove_column :meme_items, :total_cosine_similarity
   remove_column :meme_items, :avg_cosine_similarity
  end
end
