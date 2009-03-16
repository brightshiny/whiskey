class AddFlightForPretty7 < ActiveRecord::Migration
  def self.up
    Flight.create({ :partial_name => "pretty7", :action_name => "index", :controller_name => "site", :css_filename => "refinr7" })
  end

  def self.down
    f = Flight.find(:first, :conditions => ["partial_name = ? and action_name = ? and controller_name = ?", "pretty7", "index", "site"])
  end
end
