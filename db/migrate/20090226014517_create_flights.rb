class CreateFlights < ActiveRecord::Migration
  def self.up
    create_table :flights do |t|
      t.column :partial_name, :string, :null => false
      t.column :weight, :integer, :null => false, :default => 1
      t.timestamps
    end
  end

  def self.down
    drop_table :flights
  end
end
