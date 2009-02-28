class SiteController < ApplicationController
  
  COLUMN_ZOOM_FACTOR = 3
  MAX_NUMBER_OF_COLUMNS = 12
  
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
    load_memes
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
  
  def load_memes
    @memes = []
    if ! @run.nil?
      memes = Meme.find(:all, 
                        :conditions => ["run_id = ?", @run.id], 
      :include => [ :meme_items => :item_relationship ]
      )
      @memes = memes.sort_by{ |m| m.strength }.reverse.reject{ |m| m.distinct_meme_items.size <= 2 } 
      # memes.each { |m|
      #   meme_should_be_included = false
      #   required_item_strength = m.items.size / 2.0
      #   m.items.each { |i|
      #     logger.info "#{i.total_cosine_similarity(@run)} > #{required_item_strength}"
      #     if i.total_cosine_similarity(@run) > required_item_strength
      #       meme_should_be_included = true
      #     end
      #   }
      #   if meme_should_be_included
      #     @memes.push(m)
      #   end
      # }
    end
  end  
  
  def load_items
    @items_by_meme = {}
    for meme in @memes
      @items_by_meme[meme.id] = []
      meme_items = meme.distinct_meme_items.sort_by {|mi| mi.total_cosine_similarity}.reverse[0..4]
      if meme_items
        for mi in meme_items do
          @items_by_meme[meme.id].push mi.item_relationship.item
        end
      end
    end
  end
  
end
