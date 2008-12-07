class ClicksController < ApplicationController
  
  def create
    if ! params[:u].nil? && ! params[:i].nil?
      user_id = KEY.url_safe_decrypt64(params[:u])
      user = User.find(:first, :conditions => ["id = ?", user_id])
      item_id = KEY.url_safe_decrypt64(params[:i])
      item = Item.find(:first, :conditions => ["id = ?", item_id])
      if ! user.nil? && ! item.nil?
        Click.create({ :user_id => user.id, :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
        head :moved_permanently, :location => item.link # don't know what the "link" component will be called
      else
        redirect_to "/" and return false
      end
    else
      redirect_to "/" and return false
    end
  end

end

