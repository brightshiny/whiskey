class ListOfItemsController < ApplicationController
  before_filter :get_user, :get_priority
  layout nil
    
  def scroll 
    num_items_to_send = 20   
    @items = Item.find(:all, 
      :conditions => ["users.id = ?", @user.id], 
      :joins => "join feeds on (feeds.id = items.feed_id) join feed_users on (feeds.id = feed_users.feed_id) join users on (users.id = feed_users.user_id)", 
      :include => ["feed"],
      :limit => num_items_to_send, 
      :order => "published_at desc"
    )
    add_click_tracking_to_items(@items, @user.encrypted_id)
    @items = ItemForDisplay.convert_items(@items)
  end

  def get_user
    @user = determine_user
    if @user.nil?
      redirect_to "/" and return false
    end
  end
  
  def get_priority
    @priority = nil
    case params[:priority]
    when "high"
      @priority = params[:priority]
    when "medium"
      @priority = params[:priority]
    when "low"
      @priority = params[:priority]
    end
  end
  
  def index
    render :text => ""
    # num_items_to_send = 50
    # if ! params[:n].nil? && params[:n].to_i != 0 && params[:n].to_i <= 1000
    #   num_items_to_send = params[:n].to_i
    # end
    # 
    # feed_id = KEY.url_safe_decrypt64(params[:f]) unless params[:f].nil?
    # 
    # if !feed_id.nil?
    #   where_clause = "feed_users.user_id = ? and feed_users.feed_id = ?"
    #   params = [@user.id, feed_id]
    # else
    #   where_clause = "feed_users.user_id = ?"
    #   params = [@user.id]
    # end
    # 
    #   @items = Item.find_by_sql(["select STRAIGHT_JOIN `items`.* FROM `items` join feed_users on (items.feed_id = feed_users.feed_id) WHERE (#{where_clause}) ORDER BY published_at asc LIMIT 50", params].flatten)
    # 
    # add_tracking_to_items(@items, @user.encrypted_id)
    # respond_to do |format|
    #   format.atom
    # end
  end
  
private

  def add_tracking_to_items(items, encrypted_user_id)
    items.map { |item|
      encrypted_item_id = KEY.url_safe_encrypt64(item.id)
      item.content += " <img src=\"#{url_for(:controller => :reads, :action => :create, :u => encrypted_user_id, :i => encrypted_item_id)}\" alt=\"Whiskey Tracking\" /> "
      if !item.link.nil?
        item.link = "#{url_for(:controller => :clicks, :action => :create, :u => encrypted_user_id, :i => encrypted_item_id, :d => URI.encode(item.link))}"
      end
    }
  end

  def add_click_tracking_to_items(items, encrypted_user_id)
    items.map { |item|
      encrypted_item_id = KEY.url_safe_encrypt64(item.id)
      if !item.link.nil?
        item.link = "#{url_for(:controller => :clicks, :action => :create, :u => encrypted_user_id, :i => encrypted_item_id, :d => URI.encode(item.link))}"
      end
    }
  end
  
  def determine_user
    encrypted_user_id = nil
    user_id = nil
    if params[:u]
      encrypted_user_id = params[:u]
      user_id = KEY.url_safe_decrypt64(params[:u])
    elsif ! current_user.nil?
      encrypted_user_id = KEY.url_safe_encrypt64(current_user.id)
      user_id = current_user.id
    end
    user = User.find(:first, :conditions => ["id = ?", user_id])
    return user
  rescue
    return nil
  end
  
end

