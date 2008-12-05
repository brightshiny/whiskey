class Feed < ActiveRecord::Base
  has_many :items
  has_many :users, :through => :feed_users
  has_many :feed_users
end
