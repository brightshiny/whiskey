class SiteController < ApplicationController
  
  COLUMN_ZOOM_FACTOR = 4
  MAX_NUMBER_OF_COLUMNS = 16
  
  before_filter :require_user
  layout "pretty_layout" 
  
  def index
    load_flight
    load_run
    load_memes(@run)
    if ! read_fragment({ :action => "index", :run => @run.id, :flight => @flight.id })
      load_items
    else
      logger.info "Cache hit: #{action_name} | #{@run.id} | #{@flight.id}"
    end
    render :action => "index"
  end
  
  def info
    load_run
    load_memes
    render :action => "info", :layout => "layouts/default"
  end
  
  def load_flight 
    if params[:flight].nil?
      @flight = Flight.find(:first, 
                            :conditions => ["controller_name = ? and action_name = ?", controller_name, action_name], 
      :order => "id desc"
      )
    else
      @flight = Flight.find(params[:flight])
    end
    if @flight.nil?
      @flight = Flight.find(:first, 
        :conditions => ["controller_name = ? and action_name = ?", "site", "index"], 
        :order => "id desc"
      )
    end
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
    if ! @run.nil?
      @memes = Meme.find(:all, 
        :conditions => ["run_id = ?", run.id], 
        :include => [ :meme_items => :item_relationship ]
      )
      if ! @memes.nil? && ! @memes.empty?
        @memes = @memes.sort_by{ |m| m.strength }.reverse.reject{ |m| m.distinct_meme_items.size <= 2 } 
      end
    end
  end  
  
  def load_items
    @items_by_meme = {}
    for meme in @memes
      @items_by_meme[meme.id] = []
      meme_items = meme.distinct_meme_items.sort_by{ |mi| mi.total_cosine_similarity }.reverse
      if meme_items
        items_to_push = []
        for mi in meme_items do
          # if mi.item_relationship.item.content.strip.split(/\s/).size > 1
            items_to_push.push(mi.item_relationship.item)
          # end
        end
        @items_by_meme[meme.id] = items_to_push[0..4]
      end
    end
  end

  def meme    
    load_flight
    @meme = Meme.find(:first, :conditions => { :id => params[:id] }, :include => [ :meme_items => { :item_relationship => { :item => :feed } } ] )
    @distinct_meme_items = @meme.distinct_meme_items
    @words = Word.find_by_sql(["select w.id, w.word, sum(iw.count) as number_of_occurances from memes m join meme_items mi on mi.meme_id = m.id join item_relationships ir on ir.id = mi.item_relationship_id join item_words iw on iw.item_id = ir.item_id join words w on w.id = iw.word_id where m.id = ? group by w.id order by 3 desc limit 10", @meme.id])
    @page_title = "meme details for #{@meme.id}"
  end
  
end
