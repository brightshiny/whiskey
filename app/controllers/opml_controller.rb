class OpmlController < ApplicationController
  
  before_filter :login_required
  
  def show
  end
  
  def upload
    if ! params[:opml_file].nil?
      @opml = Opml.new
      @opml.content = params[:opml_file].read
      @opml.create_or_update_uris_from_array_of_feeds(current_user)
    end
  end
  
end
