class UberMemeRunAssociation < ActiveRecord::Base
  has_many :runs
  has_many :uber_memes
end
