class MemeController < ApplicationController
  
  def show
    @meme = Meme.find(params[:id], :include => [:item_relationships => :item])
  end
  
end
