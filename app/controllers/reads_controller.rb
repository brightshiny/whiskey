class ReadsController < ApplicationController
  
  def create
    if ! params[:u].nil? && ! params[:i].nil?
      user_id = KEY.url_safe_decrypt64(params[:u])
      user = User.find(:first, :conditions => ["id = ?", user_id])
      item_id = KEY.url_safe_decrypt64(params[:i])
      item = Item.find(:first, :conditions => ["id = ?", item_id])
      if ! user.nil? && ! item.nil?
        Read.create({ :user_id => user.id, :item_id => item.id, :referrer => request.referer, :ip_address => request.remote_ip })
      end
    end
    send_data Read::image_data_1x1, :type => "image/gif", :disposition => 'inline'
  end
  
end
