class AddFlightPretty2 < ActiveRecord::Migration
  def self.up
    Flight.create({ :partial_name => "pretty2", :action_name => "index", :controller_name => "site", :css_filename => "refinr2" })
  end

  def self.down
    f = Flight.find(:first, :conditions => ["partial_name = ? and action_name = ? and controller_name = ?", "pretty2", "index", "site"])
    Flight.delete(f.id) if f
  end
end
