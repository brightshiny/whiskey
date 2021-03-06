class UberMeme < ActiveRecord::Base
  belongs_to :item
  belongs_to :run
  has_many :uber_meme_items
  has_many :uber_meme_run_associations
  has_many :runs, :through => :uber_meme_run_associations
  attr_accessor :number_of_columns, :break_afterwards, :is_alpha
  
  def self.make_memes(opts={})
    run = opts[:run]
    buckets = opts[:buckets]
    cosine_similarities = opts[:cosine_similarities]

    if !run || !buckets || !cosine_similarities
      warn "UberMeme.make_meme: Missing args."
      return
    end

    prev_run = Run.find(:first, :conditions => ["user_id = ? and id < ? and ended_at is not null", run.user_id, run.id], :order => "id desc")
    prev_memes = []
    if prev_run
      prev_memes = UberMeme.find(:all, :conditions => ["run_id = :run_id", {:run_id => prev_run.id}])
    end
    
    # each bucket is a meme
    for bucket in buckets
      next unless bucket.keys.size >= 3
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
        if cosine_similarities[item_id]
          for cos in cosine_similarities[item_id].values
            item_count += 1
            item_strength += cos
          end
        end
        
        if item_count > 0
          UberMemeItem.create(:run_id => run.id, :item_id => item_id, :uber_meme_id => current_meme.id, :total_cosine_similarity => item_strength, :avg_cosine_similarity => item_strength/item_count)
        end
        total_bucket_strength += item_strength
        if lead_item_strength < item_strength
          lead_item_id = item_id
          lead_item_strength = item_strength
        end
      end
      
      current_meme.item = Item.find(lead_item_id)
      # current_meme.strength = total_bucket_strength
      current_meme.strength = current_meme.distinct_meme_items.map{ |mi| mi.total_cosine_similarity }.sum
      # memes_for_strength_calc = UberMeme.find_by_sql(["select uber_meme_id as id, sum(mean_strength_per_feed) as calculated_strength from (select umi.uber_meme_id, umi.item_id, i.id, sum(umi.total_cosine_similarity), count(i.feed_id), sum(umi.total_cosine_similarity) / count(i.feed_id) as mean_strength_per_feed, i.feed_id from uber_meme_items umi join items i on i.id = umi.item_id where umi.uber_meme_id = ? group by i.feed_id) as A", current_meme.id])
      # current_meme.strength = memes_for_strength_calc.first.calculated_strength
      current_meme.save
    end
  end
  
  def similar_to(items)
    return false if !items
    prev_meme_items = items.clone

    my_items = {}
    for uber_meme_item in self.uber_meme_items
      item = uber_meme_item.item
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
    return (common_item_count > 5) # related if > 5 items in common
  end
  
  attr_accessor :cached_distinct_meme_items
  def distinct_meme_items(run=nil)
    if self.cached_distinct_meme_items.nil?
      if ! run.nil?
        self.cached_distinct_meme_items = UberMemeItem.find(:all, :select => "distinct uber_meme_items.*", :conditions => ["uber_meme_id = ? and run_id = ?", self.id, run.id], :group => "item_id", :order => "total_cosine_similarity desc")
      else
        self.cached_distinct_meme_items = UberMemeItem.find(:all, :select => "distinct uber_meme_items.*", :conditions => ["uber_meme_id = ?", self.id], :group => "item_id", :order => "total_cosine_similarity desc")
      end
    end
    return self.cached_distinct_meme_items
  end
  
  attr_accessor :cached_strength
  def strength(run)
    if self.cached_strength.nil?
      # self.distinct_meme_items.map{ |mi| mi.total_cosine_similarity }.sum
      self.uber_meme_run_association(run).strength
    end
    return self.cached_strength
  end
  
  attr_accessor :cached_z_score_strength  
  def z_score_strength(run)
    if self.cached_z_score_strength.nil?
      # self.cached_z_score_strength = self.strength / self.run.standard_deviation_meme_strength
      self.cached_z_score_strength = self.uber_meme_run_association(run).strength_z_score
    end
    return self.cached_z_score_strength
  end
  
  attr_accessor :cached_uber_meme_run_association
  def uber_meme_run_association(run)
    if self.cached_uber_meme_run_association.nil?
      self.cached_uber_meme_run_association = UberMemeRunAssociation.find(:first, :conditions => ["uber_meme_id = ? and run_id = ?", self.id, run.id])
    end
    return self.cached_uber_meme_run_association
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
      memes = UberMeme.find_by_sql(["select sum(total_cosine_similarity) as 'calculated_meme_strength' from uber_meme_items where uber_meme_id = ? group by run_id order by run_id asc", self.id])
      last_n_strengths = memes.map{ |m| m.calculated_meme_strength }
      self.cached_strength_over_time = last_n_strengths
    end
    return self.cached_strength_over_time
  end
  
  def to_json
    self.item.to_json( :only => [ :title, :author, :link, :published_at ], :methods => [ :encrypted_id, :published_date ], :include => { :feed => { :only => [ :title, :logo ] } })
  end
   
end
