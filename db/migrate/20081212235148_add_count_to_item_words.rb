class AddCountToItemWords < ActiveRecord::Migration
  def self.up
    add_column :item_words, :count, :integer
  end

  def self.down
    remove_column :item_words, :count
  end
end
