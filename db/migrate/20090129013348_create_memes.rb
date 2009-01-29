class CreateMemes < ActiveRecord::Migration
  def self.up
    create_table :memes do |t|
      t.integer :item_id
      t.integer :run_id
      t.timestamps
    end
  end

  def self.down
    drop_table :memes
  end
end
