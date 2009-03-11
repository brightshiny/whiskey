class AddLogoToFeed < ActiveRecord::Migration
  def self.up
    add_column :feeds, :logo, :string
  end

  def self.down
    remove_column :feeds, :logo
  end
end
