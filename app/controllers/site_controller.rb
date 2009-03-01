class SiteController < ApplicationController
  
  COLUMN_ZOOM_FACTOR = 4
  MAX_NUMBER_OF_COLUMNS = 16
  
  before_filter :require_user
  layout "default" 
  
  def index
    if params[:flight].nil?
      @flight = Flight.find(:first, 
                            :conditions => ["controller_name = ? and action_name = ?", controller_name, action_name], 
      :order => "id desc"
      )
    else
      @flight = Flight.find(params[:flight])
    end
    load_run
    load_memes(@run)
    if ! read_fragment({ :action => "index", :run => @run.id, :flight => @flight.id })
      load_items
    else
      logger.info "Cache hit: #{action_name} | #{@run.id} | #{@flight.id}"
    end
    render :action => "index", :layout => "layouts/pretty_layout"
  end
  
  def info
    load_run
    load_memes
    render :action => "info", :layout => "layouts/default"
  end
  
  def load_run
    if params[:id].nil?
      user = User.find(5)
      @run = Run.find(:first, 
                      :conditions => ["user_id = ? and ended_at is not null", user.id],
      :order => "ended_at desc, id desc"
      )
    else
      @run = Run.find(params[:id])
    end
  end
  
  def load_memes(run)
    @memes = []
    if ! run.nil?
      memes = Meme.find(:all, 
        :conditions => ["run_id = ?", run.id], 
        :include => [ :meme_items => :item_relationship ]
      )
      @memes = memes.sort_by{ |m| m.strength }.reverse.reject{ |m| m.distinct_meme_items.size <= 2 } 
    end
  end  
  
  def load_items
    @items_by_meme = {}
    for meme in @memes
      logger.info "#{meme.id} ***"
      @items_by_meme[meme.id] = []
      meme_items = meme.distinct_meme_items.sort_by{ |mi| mi.total_cosine_similarity }.reverse
      if meme_items
        items_to_push = []
        for mi in meme_items do
          # if mi.item_relationship.item.content.strip.split(/\s/).size > 1
            items_to_push.push(mi.item_relationship.item)
            logger.info "PUSHING: #{mi.item_relationship.item.id}"
          # end
        end
        @items_by_meme[meme.id] = items_to_push[0..4]
      end
    end
  end
  
end
