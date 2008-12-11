class AddWordColumnToWordTable < ActiveRecord::Migration
  def self.up
    add_column :words, :word, :string, :limit => 30
  end

  def self.down
    remove_column :words, :word
  end
end
