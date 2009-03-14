class ClicksController < ApplicationController
  
  def create
    destination = "/"
    if ! params[:i].nil?
      item_id = KEY.url_safe_decrypt64(params[:i])
      item = Item.find(:first, :conditions => ["id = ?", item_id])
      if ! item.nil? 
        destination = item.link
      end 
      if ! session.nil? && ! session.session_id.nil?
        Click.create({ :session_id => session.session_id[0..254], :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
      else
        Click.create({ :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
      end
    end
    head :moved_permanently, :location => destination # don't know what the "link" component will be called
  end

end

