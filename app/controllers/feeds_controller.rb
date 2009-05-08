class FeedsController < ApplicationController
  
  def show
    @feed = Feed.find(:first, :conditions => ["id = ?", params[:id]])
  end
  
end
