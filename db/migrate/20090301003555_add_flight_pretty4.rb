class AddFlightPretty4 < ActiveRecord::Migration
  def self.up
    Flight.create({ :partial_name => "pretty4", :action_name => "index", :controller_name => "site", :css_filename => "refinr4" })
  end

  def self.down
    f = Flight.find(:first, :conditions => ["partial_name = ? and action_name = ? and controller_name = ?", "pretty4", "index", "site"])
  end
end
