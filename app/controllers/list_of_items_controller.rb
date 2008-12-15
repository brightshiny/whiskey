class ListOfItemsController < ApplicationController

  def index
    encrypted_user_id = nil
    user_id = nil
    if params[:u]
      encrypted_user_id = params[:u]
      user_id = KEY.url_safe_decrypt64(params[:u])
    elsif ! current_user.nil?
      encrypted_user_id = KEY.url_safe_encrypt64(current_user.id)
      user_id = current_user.id
    end
    @items = Item.find_by_sql "SELECT i.* from items i LEFT JOIN feed_users fu ON (fu.feed_id = i.feed_id) WHERE fu.user_id=#{user_id} ORDER BY i.published_at DESC LIMIT 50"
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
