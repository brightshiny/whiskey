require 'optparse'

class Meme < ActiveRecord::Base
  belongs_to :item
  belongs_to :run
  has_many :meme_items
  has_many :item_relationships, :through => :meme_items
  has_many :meme_relationships
  has_many :related_memes, :through => :meme_relationships
  include Graphviz
  
  attr_accessor :number_of_columns, :break_afterwards, :is_alpha
  
  def self.to_graphviz
    meme_id = nil
    opts = OptionParser.new
    opts.on("-iMEME_ID", "--id=MEME_ID") {|val| meme_id = val}
    rest = opts.parse(ARGV)
    if meme_id.nil?
      puts "I didn't understand: " + rest.join(', ') if !rest.nil?
      puts opts.to_s
      return
    end
    
    meme = Meme.find(meme_id)
    meme.to_graphviz
  end
  
  
  def self.memes_from_item_relationship_map (run, ir_map, override_memes_in_db = false)
    
    if override_memes_in_db == true && ! Meme.find(:first, :conditions => ["run_id = ?", run.id]).nil?
      puts "Cleaning run #{run.id} (destroying existing memes and associated meme_items)..."
      Run.transaction do 
        run.memes.each { |m|
          m.meme_items.destroy_all
        }
        run.memes.destroy_all
      end      
      puts "... done cleaning (#{run.id})"
    end
    
    while ir_map.keys.size > 0
      Meme.transaction do
        # create a new meme
        meme = Meme.new
        entry_item_id = ir_map.keys.shift
        meme.run = run
        meme.save
        
        # generate an ir_map, a hash[item_id] of arrays[item_relationships]
        meme_ir_map = meme_from_map(entry_item_id, ir_map)
        
        # generate meme items
        meme_ir_map.each do |item_id, item_relationships|
          item_relationships.each do |ir|
            meme_item = MemeItem.new
            meme_item.meme = meme
            meme_item.item_relationship = ir
            meme_item.save
          end
        end
        
        # tear up the sidewalk behind us
        meme_ir_map.keys.each do |k|
          ir_map.delete(k)
        end
        
        #meme.to_graphviz
      end
    end
    
    # set total and avg cosine similarities for each meme_item
    run.memes.each do |meme|
      meme.calc_stats
    end
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
  
  def self.meme_from_map(item_id, source_map)
    meme_map = Hash.new
    traversed_map = Hash.new
    if source_map.has_key?(item_id) == true
      source_map[item_id].each do |ir|
        go_deeper_into_the_rabbit_hole(ir, source_map, meme_map, traversed_map)
      end
    end
    
    # flatten map to a hash of arrays
    flattened_meme_map = Hash.new
    meme_map.each do |key, val|
      flattened_meme_map[key] = val.values
    end
    return flattened_meme_map
  end
  
  # recursion, with a guide rope.  Yay!
  def self.go_deeper_into_the_rabbit_hole(ir, source_map, meme_map, traversed_map)
    meme_map[ir.item_id] = Hash.new unless meme_map.has_key?(ir.item_id)
    meme_map[ir.item_id][ir.id] = ir
    node_id = ir.related_item_id
    return if traversed_map.has_key?(node_id)
    traversed_map[node_id] = true
    if source_map.has_key?(node_id) == true
      source_map[node_id].each do |deeper_ir|
        go_deeper_into_the_rabbit_hole(deeper_ir, source_map, meme_map, traversed_map)
      end
    end
  end
  
  attr_accessor :cached_distinct_meme_items
  def distinct_meme_items
    if self.cached_distinct_meme_items.nil?
      seen_meme_items = Hash.new
      dmi = Array.new
      meme_items = MemeItem.find(:all, :include => {:item_relationship => :item}, :conditions => ["meme_id = ?", self.id])
      meme_items.each do |mi|
        item = mi.item_relationship.item
        next if !item || seen_meme_items.has_key?(item.id)
        seen_meme_items[item.id] = true
        dmi.push mi
      end
      self.cached_distinct_meme_items = dmi
    end
    return self.cached_distinct_meme_items
  end
  
  attr_accessor :cached_items
  def items
    warn "[DEPRECATION] `meme.items is deprecrated.  Please use `meme.distinct_meme_items` and `meme.distinct_meme_items[].item_relationship.item` instead.  It's pre-cached."
    warn "[DEPRECATION] #{Kernel.caller.join("\n\t")}"
    if self.cached_items.nil?
      items = Item.find_by_sql(["select distinct i.* from memes m join meme_items mi on mi.meme_id = m.id join item_relationships ir on ir.id = mi.item_relationship_id join items i on i.id = ir.item_id where m.id = ?", self.id])
      self.cached_items = items
      # logger.info "*** I: NOT CACHE"
    else
      # logger.info "*** I: CACHE"
    end
    return self.cached_items
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
  
  def similar_to(prev_meme)
    return false if !prev_meme
    my_items = {}
    prev_meme_items = {}
    self.distinct_meme_items.each do |mi|
      for item in [mi.item_relationship.item, mi.item_relationship.related_item]
        my_items[item.id] = true if item
      end
    end
    prev_meme.distinct_meme_items.each do |mi|
      for item in [mi.item_relationship.item, mi.item_relationship.related_item]
        prev_meme_items[item.id] = true if item
      end
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
