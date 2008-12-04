class CreateReads < ActiveRecord::Migration
  def self.up
    create_table :reads do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :reads
  end
end
