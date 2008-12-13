class AddWordIndexToWords < ActiveRecord::Migration
  def self.up
    add_index :words, :word
  end
  
  def self.down
    add_index :words, :word
  end
end
