class ListOfItemsController < ApplicationController

  def index
    encrypted_user_id = nil
    if params[:u]
      encrypted_user_id = params[:u]
    elsif ! current_user.nil?
      encrypted_user_id = KEY.url_safe_encrypt64(current_user.id)
    end
    @items = Item.find :all, :limit=>50, :order=>'published_at DESC'
    @items.map { |item|
      encrypted_item_id = KEY.url_safe_encrypt64(item.id)
      item.content += " <img src=\"#{url_for(:controller => :reads, :action => :create, :u => encrypted_user_id, :i => encrypted_item_id)}\" alt=\"Whiskey Tracking\" /> "
      item.link = "#{url_for(:controller => :clicks, :action => :create, :u => encrypted_user_id, :i => encrypted_item_id, :d => URI.encode(item.link))}"
    }
    respond_to do |format|
      format.atom
    end
  end
  
end
