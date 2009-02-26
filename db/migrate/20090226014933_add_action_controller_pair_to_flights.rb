class AddActionControllerPairToFlights < ActiveRecord::Migration
  def self.up
    add_column :flights, :controller_name, :string, :null => false
    add_column :flights, :action_name, :string, :null => false
  end

  def self.down
    remove_column :flights, :controller_name
    remove_column :flights, :action_name
  end
end
