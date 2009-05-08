class Feed < ActiveRecord::Base
  has_many :items
  has_many :users, :through => :feed_users
  has_many :feed_users

  def encrypted_id
    KEY.url_safe_encrypt64(self.id)
  end

  attr_accessor :cached_last_published_item
  def last_updated_at
    if self.cached_last_published_item.nil?
      last_published_item = Item.find(:first, :conditions => ["feed_id = ?", self.id], :order => "published_at desc")
      if ! last_published_item.nil?
        self.cached_last_published_item = last_published_item
      else
        self.cached_last_published_item = Item.new
      end
    end
    return self.cached_last_published_item.published_at
  end
  
  attr_accessor :cached_items_that_have_made_the_front_page
  def items_that_have_made_the_front_page
    if self.cached_items_that_have_made_the_front_page.nil?
      self.cached_items_that_have_made_the_front_page = Item.find_by_sql(["select i.*, A.score as score from items i join (select i.id, count(i.id) as score from items i join uber_meme_items umi on umi.item_id = i.id join feeds f on f.id = i.feed_id where feed_id = ? group by i.id) as A on A.id = i.id order by A.score desc limit 10", self.id])
    end
    return self.cached_items_that_have_made_the_front_page
  end
  
  def items_published_in_the_last_n_days(n = 7)
    self.items.select{ |i| (Time.now - i.published_at) <= n.days }
  end

end
