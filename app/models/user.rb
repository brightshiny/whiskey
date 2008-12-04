class User < ActiveRecord::Base
  has_many :feeds, :through => :feed_users
  has_many :clicks
  has_many :reads
end
