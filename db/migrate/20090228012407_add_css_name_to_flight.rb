class AddCssNameToFlight < ActiveRecord::Migration
  def self.up
    add_column :flights, :css_filename, :string, :null => true
  end

  def self.down
    remove_column :flights, :css_filename
  end
end
