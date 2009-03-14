require 'RMagick'
include Magick

class ClicksController < ApplicationController
  
  def create
    if ! params[:i].nil?
      item_id = KEY.url_safe_decrypt64(params[:i])
      item = Item.find(:first, :conditions => ["id = ?", item_id])

      if ! session.nil? && ! session.session_id.nil?
        Click.create({ :session_id => session.session_id[0..254], :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
      else
        Click.create({ :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
      end
    end
    #head :moved_permanently, :location => destination # don't know what the "link" component will be called
    pixel = Image.from_blob("GIF89a\001\000\001\000??\377\377\000\000\000!?\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;").shift
    send_data pixel.to_blob, :type => 'image/gif', :disposition => 'inline'
    return
  end

end

