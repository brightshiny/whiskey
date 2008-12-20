class AddParsedAtToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :parsed_at, :timestamp
    add_index :items, :parsed_at
  end

  def self.down
    remove_column :items, :parsed_at
  end
end
