class MemeController < ApplicationController
  
  def show
    @meme = Meme.find(params[:id], :include => [:item_relationships => :item])
    respond_to do |format|
      format.html
      format.xml
    end
  end

end
