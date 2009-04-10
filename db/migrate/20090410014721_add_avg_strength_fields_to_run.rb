class AddAvgStrengthFieldsToRun < ActiveRecord::Migration
  def self.up
    add_column :runs, :meme_strength_average, :float, :null => true
    add_column :runs, :meme_strength_standard_deviation, :float, :null => true
  end

  def self.down
    remove_column :runs, :meme_strength_average
    remove_column :runs, :meme_strength_standard_deviation
  end
end
