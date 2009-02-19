class MemeItem < ActiveRecord::Base
  belongs_to :meme
  belongs_to :item_relationship
  has_one :item, :through => :item_relationship
end
