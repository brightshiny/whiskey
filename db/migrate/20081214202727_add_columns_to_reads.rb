class AddColumnsToReads < ActiveRecord::Migration
  def self.up
    add_column :reads, :user_id, :integer, :null => false
    add_column :reads, :item_id, :integer, :null => false
    add_column :reads, :referrer, :string, :length => 2048, :null => true
    add_column :reads, :ip_address, :string, :length => 15, :null => true
  end

  def self.down
    remove_column :reads, :user_id
    remove_column :reads, :item_id
    remove_column :reads, :ip_address
    remove_column :reads, :referrer
  end
end
