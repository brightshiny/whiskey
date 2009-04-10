class CreateUberMemeRunAssociations < ActiveRecord::Migration
  def self.up
    create_table :uber_meme_run_associations do |t|
      t.column :uber_meme_id, :integer, :null => false
      t.column :run_id, :integer, :null => false
      t.column :strength, :float
      t.column :strength_z_score, :float
      t.timestamps
    end
    add_index :uber_meme_run_associations, [ :uber_meme_id, :run_id ]
  end

  def self.down
    drop_table :uber_meme_run_associations
  end
end
