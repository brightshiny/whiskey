class Feed < ActiveRecord::Base
  has_many :items
  has_many :users, :through => :feed_users
end
