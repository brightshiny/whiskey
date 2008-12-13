class AddForeignKeysToItemWords < ActiveRecord::Migration
  def self.up
    add_column :item_words, :item_id, :integer
    add_column :item_words, :word_id, :integer
  end

  def self.down
    remove_column :item_words, :word_id
    remove_column :item_words, :item_id
  end
end
