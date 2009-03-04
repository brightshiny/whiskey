class MemeRelationship < ActiveRecord::Base
  belongs_to :meme, :class_name => "Meme", :foreign_key => :meme_id
  belongs_to :related_meme, :class_name => "Meme", :foreign_key => :related_meme_id
  belongs_to :meme_comparison
end
