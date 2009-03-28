class UberMeme < ActiveRecord::Base
  belongs_to :item
  belongs_to :run
  has_many :item_uber_memes
  attr_accessor :number_of_columns, :break_afterwards, :is_alpha
  
  def self.make_memes(opts={})
    run = opts[:run]
    buckets = opts[:buckets]
    cosine_similarities = opts[:cosine_similarities]

    if !run || !buckets || !cosine_similarities
      warn "UberMeme.make_meme: Missing args."
      return
    end

    prev_run = Run.find(:first, :conditions => ["user_id = ? and ended_at is not null", run.user_id], :order => "id desc")
    prev_memes = UberMeme.find(:all, :conditions => ["run_id = :run_id", {:run_id => prev_run.id}])
    
    # each bucket is a meme
    for bucket in buckets
      next unless bucket.keys.size > 2
      current_meme = nil
      
      for uber_meme in prev_memes
        # find existing similar uber_meme
        if !current_meme && uber_meme.similar_to(bucket)
          current_meme = uber_meme
        end
      end
      if current_meme.nil?
        current_meme = UberMeme.create(:run_id => run.id)
      else
        # kmb: move meme forward in runs ... problematic
        current_meme.run = run
        current_meme.save
      end
      
      # do some calcs
      total_bucket_strength = 0.0
      lead_item_id = nil
      lead_item_strength = 0.0
      for item_id in bucket.keys
        item_count = 0
        item_strength = 0.0
        for cos in cosine_similarities[item_id].values
          item_count += 1
          item_strength += cos
        end
        
        ItemUberMeme.create(:run_id => run.id, :item_id => item_id, :uber_meme_id => current_meme.id, :total_cosine_similarity => item_strength, :avg_cosine_similarity => item_strength/item_count)
        total_bucket_strength += item_strength
        if lead_item_strength < item_strength
          lead_item_id = item_id
          lead_item_strength = item_strength
        end
      end
      
      current_meme.item = Item.find(lead_item_id)
      current_meme.strength = total_bucket_strength
      current_meme.save
    end

    #meme.calc_stats
  end
  
  def similar_to(items)
    return false if !items
    prev_meme_items = items.clone

    my_items = {}
    for item_uber_meme in self.item_uber_memes
      item = item_uber_meme.item
      my_items[item.id] = true if !item.nil?
    end

    my_keys = my_items.keys
    common_item_count = 0
    my_keys.each do |k|
      if prev_meme_items.has_key?(k)
        common_item_count += 1
        prev_meme_items.delete(k)   
        my_items.delete(k)
      end
    end
    return (common_item_count > 2) # related if >2 items in common
  end

  
  def calc_stats
    # meme head = meme with max total cosine similarity
    meme_head = nil
    max_cosine_similarity = 0.0
    # strength = sum of distinct meme item total_cosine_similarity
    strength = 0.0
    seen_items = Hash.new
    
    Meme.transaction do
      self.meme_items.each do |mi|
        mi.total_cosine_similarity = mi.item.total_cosine_similarity(run)
        mi.avg_cosine_similarity = mi.item.avg_cosine_similarity(run)
        mi.save
        
        strength += mi.total_cosine_similarity unless seen_items.has_key?(mi.item.id)
        seen_items[mi.item.id] = true
        
        if mi.total_cosine_similarity > max_cosine_similarity
          max_cosine_similarity = mi.total_cosine_similarity
          meme_head = mi.item
        end
      end
      self.item = meme_head
      self.strength = strength
      self.save
    end
  end
  
  def distinct_meme_items
    return ItemUberMeme.find(:all, :conditions => ["uber_meme_id = ? and run_id = ?", self.id, self.run.id])
  end
  
  attr_accessor :cached_z_score_strength  
  def z_score_strength
    if self.cached_z_score_strength.nil?
      self.cached_z_score_strength = self.strength / self.run.standard_deviation_meme_strength
      # logger.info "*** Z: NOT CACHE"
    else
      # logger.info "*** Z: CACHE"
    end
    return self.cached_z_score_strength
  end
  
  attr_accessor :cached_strength_trend
  def strength_trend
    if self.cached_strength_trend.nil?
      memes = self.related_memes.select{ |m| m.id < self.id }
      strengths_to_consider = 3
      if memes.size > strengths_to_consider
        last_n_strengths = memes.map{ |m| m.strength }[0..(strengths_to_consider-1)]
        avg_recent_strength = last_n_strengths.sum / strengths_to_consider
        strength_trend = self.strength - avg_recent_strength
      else
        strength_trend = 0
      end
      self.cached_strength_trend = strength_trend
    end
    return self.cached_strength_trend
  end
  
  attr_accessor :cached_strength_over_time
  def strength_over_time
    if self.cached_strength_over_time.nil?
      memes = self.related_memes.select{ |m| m.id < self.id }
      last_n_strengths = memes.map{ |m| m.strength }
      self.cached_strength_over_time = last_n_strengths
    end
    return self.cached_strength_over_time
  end
  
  attr_accessor :cached_related_memes
  def related_memes(number_of_related_memes=60)
    if self.cached_related_memes.nil?
      forward_sql_select = "select "
      forward_sql_from = "from meme_relationships m0 "
      forward_sql_join = ""
      forward_sql_where = "where m0.meme_id = #{self.id}"
      number_of_related_memes.times do |n|
        forward_sql_select += " m#{n}.related_meme_id as m#{n}_id "
        if n != number_of_related_memes-1
          forward_sql_select += ", "
        end
        forward_sql_join   += "left join meme_relationships m#{n+1} on m#{n+1}.meme_id = m#{n}.related_meme_id "
      end
      forward_sql = "#{forward_sql_select} #{forward_sql_from} #{forward_sql_join} #{forward_sql_where}"
      forward_meme_ids = Meme.connection.select_rows(forward_sql).first
      if forward_meme_ids.nil?
        forward_meme_ids = []
      end
            
      backward_sql_select = "select "
      backward_sql_from = "from meme_relationships m0 "
      backward_sql_join = ""
      backward_sql_where = "where m0.related_meme_id = #{self.id}"
      number_of_related_memes.times do |n|
        backward_sql_select += " m#{n}.meme_id as m#{n}_id "
        if n != number_of_related_memes-1
          backward_sql_select += ", "
        end
        backward_sql_join   += "left join meme_relationships m#{n+1} on m#{n+1}.related_meme_id = m#{n}.meme_id "
      end
      backward_sql = "#{backward_sql_select} #{backward_sql_from} #{backward_sql_join} #{backward_sql_where}"
      backward_meme_ids = Meme.connection.select_rows(backward_sql).first
      if backward_meme_ids.nil?
        backward_meme_ids = []
      end
    
      meme_ids = (forward_meme_ids + backward_meme_ids).uniq.select{ |id| ! id.nil? && id.to_i != self.id }
      self.cached_related_memes = Meme.find(:all, :conditions => ["id in (?)", meme_ids], :order => "id desc")
    end
    return self.cached_related_memes
  end
 
end
