class SiteController < ApplicationController
  
  before_filter :require_user
  layout "default" 
  
  def index
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
  
  def pretty
    index
    render :action => "pretty", :layout => "layouts/pretty_layout"
  end
  
end
