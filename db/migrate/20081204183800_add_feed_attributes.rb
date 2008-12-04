class AddFeedAttributes < ActiveRecord::Migration
  def self.up
    add_column :feeds, :title, :string, :null => false
    add_column :feeds, :link, :string, :null => false
  end

  def self.down
  end
end
