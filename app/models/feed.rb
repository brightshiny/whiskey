class Feed < ActiveRecord::Base
  has_many :items
  has_many :users, :through => :feed_users
  has_many :feed_users

  def encrypted_id
    KEY.url_safe_encrypt64(self.id)
  end

end
