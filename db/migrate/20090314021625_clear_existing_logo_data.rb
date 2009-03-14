class ClearExistingLogoData < ActiveRecord::Migration
  def self.up
    execute "UPDATE feeds SET logo=null WHERE logo IS NOT NULL"
  end

  def self.down
  end
end
