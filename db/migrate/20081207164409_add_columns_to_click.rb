class AddColumnsToClick < ActiveRecord::Migration
  def self.up
    add_column :clicks, :user_id, :integer, :null => false
    add_column :clicks, :item_id, :integer, :null => false
    add_column :clicks, :referrer, :string, :length => 2048, :null => true
    add_column :clicks, :ip_address, :string, :length => 15, :null => true
  end

  def self.down
    remove_column :clicks, :user_id
    remove_column :clicks, :item_id
    remove_column :clicks, :ip_address
    remove_column :clicks, :referrer
  end
end
