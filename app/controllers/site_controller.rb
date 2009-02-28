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
    if ! read_fragment({ :action => "index", :run => @run.id, :flight => @flight.id })
      load_memes
    else
      logger.info "Cache hit: #{action_name} | #{@run.id} | #{@flight.id}"
    end
    @items_by_meme = {}
    for meme in @memes
      items = []
      meme.items.each { |item|
        if items.empty? || items.select{ |i| i.title == item.title }.empty?
          items.push(item)
        end
      }
      if @items_by_meme[meme.id].nil?
        @items_by_meme[meme.id] = items.sort_by{ |i| i.total_cosine_similarity(@run) }.reverse[0..2]
      end
    end
    render :action => "index", :layout => "layouts/pretty_layout"
  end
  
  def info
    load_run_and_memes
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

  def load_memes
    if ! @run.nil?
      @memes = Meme.find(:all, 
        :conditions => ["run_id = ?", @run.id], 
        :include => [ :meme_items => :item_relationship ]
      )
      @memes = @memes.sort_by{ |m| m.strength }.reverse.reject{ |m| m.items.size <= 2 }
    end
  end  
  
end

