class Item < ActiveRecord::Base
  has_many :readers, :through => :reads, :source => :user
  has_many :clickers, :through => :clicks, :source => :user
  has_many :words, :through => :item_words
  has_many :item_words
  belongs_to :feed
end
