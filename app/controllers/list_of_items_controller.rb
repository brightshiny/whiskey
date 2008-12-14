class ListOfItemsController < ApplicationController

  def index
    @items = Item.find :all, :limit=>50, :order=>'published_at DESC'
    puts @items.type
    respond_to do |format|
      format.atom
    end
  end
  
end
