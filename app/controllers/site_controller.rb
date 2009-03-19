class SiteController < ApplicationController
  
  COLUMN_ZOOM_FACTOR = 4
  MAX_NUMBER_OF_COLUMNS = 12
  
  def index
    load_run
    if ! read_fragment({ :action => "index", :run => @run.id, :flight => @flight.id, :user => current_user })    
      load_memes(@run)
      @maximum_meme_strength = @memes.map{ |m| m.strength }.max
      load_items
      if @run != Run.current(5)
        @archive = true
      end
    else
      logger.info "Cache hit: #{action_name} | #{@run.id} | #{@flight.id}"
    end
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
    if ! read_fragment({ :action => "meme", :id => params[:id], :flight => @flight.id })      
      @meme = Meme.find(:first, :conditions => { :id => params[:id] }, :include => [ :meme_items => { :item_relationship => { :item => :feed } } ] )
      potential_items = @meme.related_memes.map{ |m| m.distinct_meme_items }.flatten.map{ |mi| mi.item }.sort_by{ |i| i.published_at }.reverse
      items_hash = {}
      potential_items.each { |i|
        items_hash[i.id] = i
      }
      @items = []
      items_hash.keys.each { |k|
        @items.push(items_hash[k])
      }
      @words = Word.find_by_sql(["select w.id, w.word, sum(iw.count) as number_of_occurances from memes m join meme_items mi on mi.meme_id = m.id join item_relationships ir on ir.id = mi.item_relationship_id join item_words iw on iw.item_id = ir.item_id join words w on w.id = iw.word_id where m.id = ? group by w.id order by 3 desc limit 10", @meme.id])
      @words_for_twitter_search = []
      number_of_words_for_twitter_search = 2
      @words[0..(number_of_words_for_twitter_search-1)].each { |partial_word| 
        reg = Regexp.new("\s#{partial_word.word}.*?\s",true)
        all_matching_words = Gobbler::GItem.extract_text(@meme.item.content).strip.scan(reg).map{ |s| s.strip }
        matching_words = {}
        all_matching_words.each { |word| 
          word = word.gsub(/[a-z]s$/i,'')
          if matching_words[word].nil?
            matching_words[word] = 0
          end
          matching_words[word] += 1
        }
        matching_words = matching_words.sort { |a,b| b[1] <=> a[1] }
        word = matching_words[0][0].gsub(/\W/,'').gsub(/\342\200\231s/,'')
        @words_for_twitter_search.push(word)
      }
    
      @page_title = "meme details for #{@meme.id}"
      @meme_strength_graph = open_flash_chart_object(960,300,"/graph/meme_strength/#{@meme.id}")
      @items_published_graph = open_flash_chart_object(960,100,"/graph/items_published/#{@meme.id}")
    end
  end
  
end
