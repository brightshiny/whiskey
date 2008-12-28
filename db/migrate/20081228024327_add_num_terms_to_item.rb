class AddNumTermsToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :word_count, :integer
  end

  def self.down
    remove_column :items, :word_count
  end
end
