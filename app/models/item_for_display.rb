class ItemForDisplay < ActiveRecord::BaseWithoutTable
  
  attr_accessor :title, :description, :link, :author, :feed_name, :published_at
  
  def initialize(item)
    @title = item.title
    @description = ItemForDisplay.clean(item.content)
    @link = item.link
    @feed_name = item.feed.title
    @published_at = item.published_at
    @author = item.author
  end
  
  def self.convert_items(array_of_items)
    a = []
    array_of_items.each { |item|
      i = ItemForDisplay.new(item)
      a.push({ 
        :title => i.title, 
        :description => i.description, 
        :link => i.link, 
        :author => i.author, 
        :feed_name => i.feed_name, 
        :published_at => i.published_at
      })
    }
  end
  
  def self.clean(text)
    text = text.slice(0..200)
  end
  
end
