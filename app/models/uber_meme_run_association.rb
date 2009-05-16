class UberMemeRunAssociation < ActiveRecord::Base
  has_many :runs
  belongs_to :uber_meme
end
