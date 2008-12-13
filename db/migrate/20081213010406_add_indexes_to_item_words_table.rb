class AddIndexesToItemWordsTable < ActiveRecord::Migration
  def self.up
    add_index :item_words, :item_id
    add_index :item_words, :word_id
  end
  
  def self.down
    remove_index :item_words, :item_id
    remove_index :item_words, :word_id
  end
end
