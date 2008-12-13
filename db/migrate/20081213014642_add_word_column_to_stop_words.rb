class AddWordColumnToStopWords < ActiveRecord::Migration
  def self.up
    add_column :stop_words, :word, :string, :limit => 30
    add_index :stop_words, :word, :unique => true
  end

  def self.down
    remove_column :stop_words, :word
  end
end
