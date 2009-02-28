class MemeController < ApplicationController

  before_filter :require_user, :except => :show

  def show
    @meme = Meme.find(params[:id], :include => [ :meme_items => {:item_relationship => { :item => :feed} } ] )
  
    seen_meme_items = Hash.new
    @distinct_meme_items = Array.new
    @meme.meme_items.each do |mi|
      item = mi.item_relationship.item
      next if seen_meme_items.has_key?(item.id)
      seen_meme_items[item.id] = true
      @distinct_meme_items.push mi
    end
    respond_to do |format|
      format.html
      format.xml
    end
  end

end
