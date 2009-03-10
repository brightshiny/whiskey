class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.integer :item_id, :null => false
      t.integer :height, :precision => 5
      t.integer :width, :precision => 5
      t.string :local_src, :limit => 80
      t.string :original_src, :null => false
      t.string :type, :limit => 10
      t.timestamps
    end
    add_index :images, :item_id
  end

  def self.down
    drop_table :images
  end
end
