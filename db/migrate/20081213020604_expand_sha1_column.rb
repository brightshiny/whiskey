class ExpandSha1Column < ActiveRecord::Migration
  def self.up
    change_column :items, :content_sha1, :string, :limit => 40
  end

  def self.down
    change_column :items, :content_sha1, :string, :limit => 20
  end
end
