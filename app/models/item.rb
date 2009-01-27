class Item < ActiveRecord::Base
  has_many :readers, :through => :reads, :source => :user
  has_many :clickers, :through => :clicks, :source => :user
  has_many :words, :through => :item_words
  has_many :item_words
  belongs_to :feed
  has_many :item_relationships
  has_many :related_items, :through => :item_relationships

  attr_accessor :score

  def self.recent_items(number_of_items_to_return = 100)
    find(:all, :include => [ :words ], :order => "published_at desc", :limit => number_of_items_to_return)
  end

  attr_accessor :cached_string_of_contained_words
  def string_of_contained_words
    if self.cached_string_of_contained_words.nil?
      # self.cached_string_of_contained_words = self.words.map{ |w| w.word }.join(" ")
      s = ""
      i = Item.find(:first, :conditions => ["id = ?", self.id], :include => [{:item_words, :word}])
      i.item_words.each { |iw|
        iw.count.times do |n| 
          s += "#{iw.word.word} "
        end 
      } 
      self.cached_string_of_contained_words = s
    end
    return self.cached_string_of_contained_words
  end

  def self.recent_items_as_collections_of_words
    items_as_collections_of_words = []
    most_recent_items = self.find(:all, :include => [ :words ], :order => "published_at desc", :limit => number_of_items_to_return)
    most_recent_items.each do |i|
      items_as_collections_of_words.push(i.words.map{ |w| w.word }.flatten.join(" "))
    end
    return items_as_collections_of_words
  end
  
end
