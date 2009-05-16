class CreateTwitterClients < ActiveRecord::Migration
  def self.up
    create_table :twitter_clients do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :twitter_clients
  end
end
