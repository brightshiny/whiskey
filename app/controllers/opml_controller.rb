class OpmlController < ApplicationController
  before_filter :require_user
  
  def show
    @user = current_user
    @feeds = @user.feeds
    respond_to do |format|
      format.html
      format.xml
    end
  end
  
  def upload
    if ! params[:opml_file].nil?
      @opml = Opml.new
      @opml.content = params[:opml_file].read
      @opml.create_or_update_uris_from_array_of_feeds(current_user)
    end
  end
  
  def add_feed 
    if ! params[:feed_url].nil?
      @feed = Feed.find(:first, :conditions => ["link = ?", params[:feed_url]])
      if @feed.nil?
        @feed = Feed.create({ :link => params[:feed_url] })
      end
      @feed_user = FeedUser.find(:first, :conditions => ["feed_id = ? and user_id = ?", @feed.id, current_user.id])
      if @feed_user.nil?
        @already_existed = false
        @feed_user = FeedUser.create({ :feed_id => @feed.id, :user_id => current_user.id })
      else
        @already_existed = true
      end
    end
    respond_to do |format|
      format.js
    end
  end
  
  def delete_feed
    if ! params[:feed_id].nil?
      @feed_id = params[:feed_id]
      feed_user = FeedUser.find(:first, :conditions => ["feed_id = ? and user_id = ?", params[:feed_id], current_user.id])
      if ! feed_user.nil?
        feed_user.destroy
      end
    end
    respond_to do |format|
      format.js
    end
  end
  
end
