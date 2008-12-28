class AddTermFrequencyToItemWords < ActiveRecord::Migration
  def self.up
    add_column :item_words, :term_frequency, :decimal, :precision => 10, :scale => 9
    remove_column :item_words, :created_at
    remove_column :item_words, :updated_at
  end

  def self.down
    remove_column :item_words, :term_frequency
    add_column :item_words, :created_at, :timestamp
    add_column :item_words, :updated_at, :timestamp
  end
end
