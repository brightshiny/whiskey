class RunEnhanced < ActiveRecord::Migration
  def self.up
    add_column :runs, :distinct_term_count, :integer, :null => false, :default => 0
    add_column :runs, :started_at, :timestamp
    add_column :runs, :ended_at, :timestamp
  end
  
  def self.down
    remove_column :runs, :distinct_term_count
    remove_column :runs, :started_at
    remove_column :runs, :ended_at
  end
end
