class SiteController < ApplicationController
  
  COLUMN_ZOOM_FACTOR = 4
  MAX_NUMBER_OF_COLUMNS = 12
  
  def index
    load_run
    if ! read_fragment({ :action => "index", :id => @run.id, :flight => @flight.id, :user => current_user })    
      load_memes(@run)
      if @run != Run.current(5)
        @archive = true
      end
    else
      logger.info "Cache hit: #{action_name} | #{@run.id} | #{@flight.id}"
    end
    minutes_until_expiration = 30 - ((Time.now - @run.ended_at)/(60)).floor <= 0 ? 0 : 30 - ((Time.now - @run.ended_at)/(60)).floor
    expires_in minutes_until_expiration
    render :action => "index", :layout => "layouts/pretty_layout_7_without_container"
  end
  
  def current
    load_run
    respond_to do |format|
      format.html { render :text => @run.encrypted_id }
      format.json { @run.to_json( :only => :encrypted_id ) }
    end
  end
  
  def info
    load_run
    load_memes
    render :action => "info", :layout => "layouts/default"
  end
  
  def load_run
    if !params[:id].nil?
      @run = Run.find(:first, :conditions => ["id = ? and ended_at is not null", params[:id]])
    end
    unless @run
      @run = Run.find(:first, :conditions => ["user_id = ? and ended_at is not null", 5], :order => "id desc")
    end
  end
  
  def load_memes(run)
    @memes = []
    if ! run.nil?
      @memes = UberMeme.find(:all, 
        :joins => "join uber_meme_run_associations on uber_meme_run_associations.uber_meme_id = uber_memes.id",
        :conditions => ["uber_meme_run_associations.run_id = ?", run.id],
        :order => "uber_meme_run_associations.strength_z_score desc"
      )
    end
  end  

  def meme  
    #@meme = Meme.find(:first, :conditions => { :id => params[:id] }, :include => [ :meme_items => { :item_relationship => { :item => :feed } } ] )
    @meme = UberMeme.find(:first, :conditions => { :id => params[:id] })
    @page_title = "meme details" # for #{@meme.id}"
    if ! read_fragment({ :action => "meme", :id => params[:id], :flight => @flight.id })
      @items = @meme.distinct_meme_items.map{ |dmi| dmi.item }
      @words = Word.find_by_sql(["select w.id, w.word, sum(iw.count) as number_of_occurances from uber_memes m join uber_meme_items ium on ium.uber_meme_id = m.id join item_words iw on iw.item_id = ium.item_id join words w on w.id = iw.word_id where m.id = ? group by w.id order by 3 desc limit 10", @meme.id])
      
      @words_for_twitter_search = []
      number_of_words_for_twitter_search = 2
      big_giant_content_blob = @meme.distinct_meme_items.map{ |mi| mi.item.content }.flatten.join(" ")
      @words.each { |partial_word| 
        reg = Regexp.new("\s#{partial_word.word}.*?\s",true)
        all_matching_words = Gobbler::GItem.extract_text(big_giant_content_blob).strip.scan(reg).map{ |s| s.strip.gsub(/\342\200\231s/,'').gsub(/\342\200\235/,'').gsub(/\Ws/,'').gsub(/[^a-z0-9]/i,'') }
        matching_words = {}
        all_matching_words.each { |word| 
          # word = word.gsub(/([a-z])s$/i,'\1') # depluralize
          if matching_words[word].nil?
            matching_words[word] = 0
          end
          matching_words[word] += 1
        }
        matching_words = matching_words.sort { |a,b| b[1] <=> a[1] }
        begin
          if matching_words[0][0].size > 0
            word = matching_words[0][0].downcase
            @words_for_twitter_search.push(word)
          end
        rescue
          # do nothing
        end
      }
      @words_for_twitter_search = @words_for_twitter_search[0..(number_of_words_for_twitter_search-1)]
      
      @meme_strength_graph = open_flash_chart_object(960,300,"/graph/meme_strength/#{@meme.id}")
      @items_published_graph = open_flash_chart_object(960,100,"/graph/items_published/#{@meme.id}")
    end
  end

#  def meme    
#    @meme = Meme.find(:first, :conditions => { :id => params[:id] }, :include => [ :meme_items => { :item_relationship => { :item => :feed } } ] )
#    potential_items = @meme.related_memes.map{ |m| m.distinct_meme_items }.flatten.map{ |mi| mi.item }.sort_by{ |i| i.published_at }.reverse
#    items_hash = {}
#    potential_items.each { |i|
#      items_hash[i.id] = i
#    }
#    @items = []
#    items_hash.keys.each { |k|
#      @items.push(items_hash[k])
#    }
#    @words = Word.find_by_sql(["select w.id, w.word, sum(iw.count) as number_of_occurances from memes m join meme_items mi on mi.meme_id = m.id join item_relationships ir on ir.id = mi.item_relationship_id join item_words iw on iw.item_id = ir.item_id join words w on w.id = iw.word_id where m.id = ? group by w.id order by 3 desc limit 10", @meme.id])
#    @page_title = "meme details for #{@meme.id}"
#    @meme_strength_graph = open_flash_chart_object(960,300,"/graph/meme_strength/#{@meme.id}")
#    @items_published_graph = open_flash_chart_object(960,100,"/graph/items_published/#{@meme.id}")
#  end
  
end
