class Item < ActiveRecord::Base
  has_many :readers, :through => :reads, :source => :user
  has_many :clickers, :through => :clicks, :source => :user
  has_many :words, :through => :item_words
  has_many :item_words
  belongs_to :feed
  
  # def method_missing(method, *args) 
  #   if ! method.to_s.match(/display_non_nil/)
  #     super
  #   else
  #     potentially_nil_attribute = method.to_s.gsub(/display_non_nil_/,'')
  #     if ! self.methods.include?(potentially_nil_attribute)
  #       super
  #     else
  #       value = self.send(potentially_nil_attribute)
  #       non_nil_value = ""
  #       if ! value.nil?
  #         non_nil_value = value
  #       end
  #       return non_nil_value
  #     end
  #   end
  # end

  def self.recent_items(number_of_items_to_return = 100)
    find(:all, :include => [ :words ], :order => "published_at desc", :limit => number_of_items_to_return)
  end

  attr_accessor :cached_string_of_contained_words
  def string_of_contained_words
    if self.cached_string_of_contained_words.nil?
      self.cached_string_of_contained_words = self.words.map{ |w| w.word }.join(" ")
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
