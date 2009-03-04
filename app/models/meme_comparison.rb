class MemeComparison < ActiveRecord::Base
  belongs_to :run, :class_name => "Run", :foreign_key => :run_id
  belongs_to :related_run, :class_name => "Run", :foreign_key => :related_run_id
  has_many :meme_relationships
end
