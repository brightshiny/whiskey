class CreateUberMemes < ActiveRecord::Migration
  def self.up
    create_table :uber_memes do |t|
      t.integer  "run_id", :null => false
      t.integer  "item_id"
      t.decimal  "strength",   :precision => 10, :scale => 5
      t.timestamps
    end
    add_index :uber_memes, :item_id
    add_index :uber_memes, :run_id
  end

  def self.down
    drop_table :uber_memes
  end
end
