require 'monitor'
class Gobbler::FeedBag
  include MonitorMixin
  
  def initialize(items)
    @items = items
    super()
  end

  def push(item)
    synchronize do
      @items.push item
    end
  end
  
  def get_next
    synchronize do 
      @items.pop
    end
  end
end