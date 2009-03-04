class CreateMemeComparisons < ActiveRecord::Migration
  def self.up
    create_table :meme_comparisons do |t|
      t.integer :run_id
      t.integer :related_run_id
      t.timestamps
    end
    add_index :meme_comparisons, :run_id
    add_index :meme_comparisons, :related_run_id
  end

  def self.down
    drop_table :meme_comparisons
  end
end
