class CreateDeweys < ActiveRecord::Migration
  def self.up
    create_table :deweys do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :deweys
  end
end
