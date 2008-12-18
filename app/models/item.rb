class Item < ActiveRecord::Base
  has_many :readers, :through => :reads, :source => :user
  has_many :clickers, :through => :clicks, :source => :user
  has_many :words, :through => :item_words
  has_many :item_words
  belongs_to :feed
  
  def method_missing(method, *args) 
    if ! method.to_s.match(/display_non_nil/)
      super
    else
      potentially_nil_attribute = method.to_s.gsub(/display_non_nil_/,'')
      if ! self.methods.include?(potentially_nil_attribute)
        super
      else
        value = self.send(potentially_nil_attribute)
        non_nil_value = ""
        if ! value.nil?
          non_nil_value = value
        end
        return non_nil_value
      end
    end
  end
  
end
