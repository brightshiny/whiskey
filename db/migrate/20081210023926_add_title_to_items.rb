class AddTitleToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :title, :string
  end

  def self.down
    remove_column :items, :title
  end
end
