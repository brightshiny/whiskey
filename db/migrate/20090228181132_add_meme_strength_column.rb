class AddMemeStrengthColumn < ActiveRecord::Migration
  def self.up
   add_column :memes, :strength, :decimal, :precision => 10, :scale => 5
  end

  def self.down
   remove_column :memes, :strength
  end
end
