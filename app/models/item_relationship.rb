class ItemRelationship < ActiveRecord::Base
  belongs_to :item, :class_name => "Item", :foreign_key => :item_id
  belongs_to :related_item, :class_name => "Item", :foreign_key => :related_item_id
  belongs_to :run
end
