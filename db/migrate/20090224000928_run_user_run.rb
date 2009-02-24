class RunUserRun < ActiveRecord::Migration
  def self.up
    add_column :runs, :user_id, :integer
    add_index  :runs, :user_id
  end

  def self.down
    remove_column :runs, :user_id
  end
end
