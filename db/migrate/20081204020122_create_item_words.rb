class CreateItemWords < ActiveRecord::Migration
  def self.up
    create_table :item_words do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :item_words
  end
end
