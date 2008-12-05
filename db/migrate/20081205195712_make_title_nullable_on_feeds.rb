class MakeTitleNullableOnFeeds < ActiveRecord::Migration
  def self.up
    change_column :feeds, :title, :string, :null => true
  end

  def self.down
    change_column :feeds, :title, :string, :null => false
  end
end
