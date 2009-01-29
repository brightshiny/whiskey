class MemeItem < ActiveRecord::Base
  belongs_to :meme
  belongs_to :item_relationship
end
