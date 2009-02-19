class RunEnhanced2 < ActiveRecord::Migration
  def self.up
    add_column :runs, :skip_single_terms, :boolean, :default => false
  end

  def self.down
    remove_column :runs, :skip_single_terms
  end
end
