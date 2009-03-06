class AddFlight5 < ActiveRecord::Migration
  def self.up
    Flight.create({ :partial_name => "pretty5", :action_name => "index", :controller_name => "site", :css_filename => "refinr5" })
  end

  def self.down
    f = Flight.find(:first, :conditions => ["partial_name = ? and action_name = ? and controller_name = ?", "pretty5", "index", "site"])
  end
end
