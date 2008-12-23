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
  
end
