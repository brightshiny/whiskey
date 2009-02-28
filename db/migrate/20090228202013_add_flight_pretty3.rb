class AddFlightPretty3 < ActiveRecord::Migration
  def self.up
    Flight.create({ :partial_name => "pretty3", :action_name => "index", :controller_name => "site", :css_filename => "refinr3" })
  end

  def self.down
    f = Flight.find(:first, :conditions => ["partial_name = ? and action_name = ? and controller_name = ?", "pretty3", "index", "site"])
  end
end
