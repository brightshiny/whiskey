class ItemForDisplay < ActiveRecord::BaseWithoutTable
  
  attr_accessor :id, :title, :description, :link, :author, :feed_name, :feed_link, :published_at
  
  def initialize(item)
    @id = KEY.url_safe_encrypt64(item.id)
    @title = item.title
    @description = ItemForDisplay.clean(item.content)
    @link = item.link
    @feed_name = item.feed.title
    @feed_link = item.feed.link
    @published_at = item.published_at
    @author = item.author
  end
  
  def self.convert_items(array_of_items)
    a = []
    array_of_items.each { |item|
      i = ItemForDisplay.new(item)
      a.push({ 
        :id => i.id, 
        :title => i.title, 
        :description => i.description, 
        :link => i.link, 
        :author => i.author, 
        :feed_name => i.feed_name, 
        :feed_link => i.feed_link, 
        :published_at => i.published_at.strftime('%m/%d/%Y %I:%M%p')
      })
    }
    return a
  end
  
  def self.clean(text)
    text = text.slice(0..200)
  end
  
end
