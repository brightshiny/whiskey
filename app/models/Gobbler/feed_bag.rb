require 'monitor'
class Gobbler::FeedBag
  include MonitorMixin
  
  def initialize(feeds)
    @feeds = feeds
    super()
  end
  
  def get_next
    synchronize do 
      @feeds.pop
    end
  end
end