class FeedsController < ApplicationController
  
  before_filter :require_user
  def show
    @feed = Feed.find(:first, :conditions => ["id = ?", params[:id]])
  end
  
end
