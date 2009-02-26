class SiteController < ApplicationController
  
  before_filter :require_user
  layout "default" 
  
  def index
    load_run_and_memes
    if params[:flight].nil?
      @flight = Flight.find(:first, 
        :conditions => ["controller_name = ? and action_name = ?", controller_name, action_name], 
        :order => "id desc"
      )
    else
      @flight = Flight.find(params[:flight])
    end
    render :action => "index", :layout => "layouts/pretty_layout"
  end
  
  def info
    load_run_and_memes
    render :action => "info", :layout => "layouts/default"
  end

  def load_run_and_memes
    if params[:id].nil?
      user = User.find(5)
      @run = Run.find(:first, 
        :conditions => ["user_id = ? and ended_at is not null", user.id],
        :order => "ended_at desc, id desc"
      )
    else
      @run = Run.find(params[:id])
    end
    if ! @run.nil?
      @memes = Meme.find(:all, 
        :conditions => ["run_id = ?", @run.id], 
        :include => [ :meme_items => :item_relationship ]
      )
      @memes = @memes.sort_by{ |m| m.strength }.reverse.reject{ |m| m.items.size <= 2 }
    end
  end
  
end

