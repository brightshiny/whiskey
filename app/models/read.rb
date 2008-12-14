class Read < ActiveRecord::Base
  belongs_to :user
  belongs_to :item
  
  @@image_data_1x1 = nil
  def self.image_data_1x1
    if @@image_data_1x1.nil?
      logger.info "going to have ot load from fs"
    end
    @@image_data_1x1 ||= File::open("#{RAILS_ROOT}/public/images/1x1.gif").read
  end
  
end
