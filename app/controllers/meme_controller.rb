class MemeController < ApplicationController

  before_filter :require_user

  def show
    @meme = Meme.find(params[:id], :include => [:item_relationships => :item])
    respond_to do |format|
      format.html
      format.xml
    end
  end

end
