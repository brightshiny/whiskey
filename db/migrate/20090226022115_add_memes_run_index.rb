class AddMemesRunIndex < ActiveRecord::Migration
  def self.up
    add_index :memes, :run_id
  end

  def self.down
    remove_index :memes, :run_id
  end
end
