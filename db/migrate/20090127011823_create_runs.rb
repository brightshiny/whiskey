class CreateRuns < ActiveRecord::Migration
  def self.up
    create_table :runs do |t|
      t.integer :k
      t.integer :n
      t.integer :maximum_matches_per_query_vector
      t.decimal :minimum_cosine_similarity, :precision => 10, :scale => 9
      t.timestamps
    end
  end

  def self.down
    drop_table :runs
  end
end
