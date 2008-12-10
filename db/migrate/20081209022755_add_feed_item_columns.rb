class AddFeedItemColumns < ActiveRecord::Migration
  def self.up
    add_column :feeds, :gobbled_at, :timestamp
    add_column :items, :link, :string
    add_column :items, :author, :string
    add_column :items, :published_at, :timestamp
    add_column :items, :content, :text
    add_column :items, :content_sha1, :string, :limit => 20
    add_column :items, :feed_id, :integer, :null => false
    add_index :items, [:feed_id, :link ]
  end

  def self.down
    remove_column :feeds, :gobbled_at
    remove_column :items, :link
    remove_column :items, :author
    remove_column :items, :published_at
    remove_column :items, :content
    remove_column :items, :content_sha1
    remove_column :items, :feed_id
  end
end
