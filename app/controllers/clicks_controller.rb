class ClicksController < ApplicationController
  
  def create
    destination = "/"
    if ! params[:i].nil?
      item_id = KEY.url_safe_decrypt64(params[:i])
      item = Item.find(:first, :conditions => ["id = ?", item_id])
      if ! item.nil? 
        destination = item.link
      end
      if ! params[:u].nil? 
        user_id = KEY.url_safe_decrypt64(params[:u])
        user = User.find(:first, :conditions => ["id = ?", user_id])
        if ! user.nil? && ! item.nil?
          Click.create({ :user_id => user.id, :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
        end
      end
    end
    head :moved_permanently, :location => destination # don't know what the "link" component will be called
  end

end

