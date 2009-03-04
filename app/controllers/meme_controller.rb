class MemeController < ApplicationController

  before_filter :require_user, :except => :show

  def show
    @meme = Meme.find(params[:id], :include => [ :meme_items => {:item_relationship => { :item => :feed} } ] )
    @prev_memes = @meme.related_memes
    @distinct_meme_items = @meme.distinct_meme_items
    
    respond_to do |format|
      format.html
      format.xml
    end
  end

end
