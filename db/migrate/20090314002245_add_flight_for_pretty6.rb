class AddFlightForPretty6 < ActiveRecord::Migration
  def self.up
    Flight.create({ :partial_name => "pretty6", :action_name => "index", :controller_name => "site", :css_filename => "refinr6" })
  end

  def self.down
    f = Flight.find(:first, :conditions => ["partial_name = ? and action_name = ? and controller_name = ?", "pretty6", "index", "site"])
  end
end
