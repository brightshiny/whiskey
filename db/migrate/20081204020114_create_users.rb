class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :nickname, :limit => 15
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
