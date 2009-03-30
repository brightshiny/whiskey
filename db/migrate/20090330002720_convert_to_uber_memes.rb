class ConvertToUberMemes < ActiveRecord::Migration
  def self.up
    Run.convert_to_uber_memes
  end

  def self.down
  end
end
