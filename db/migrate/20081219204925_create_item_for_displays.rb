class CreateItemForDisplays < ActiveRecord::Migration
  def self.up
    create_table :item_for_displays do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :item_for_displays
  end
end
