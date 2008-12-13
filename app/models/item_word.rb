class ItemWord < ActiveRecord::Base
  belongs_to :word
  belongs_to :item
end
