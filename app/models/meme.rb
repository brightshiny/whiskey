require 'optparse'

class Meme < ActiveRecord::Base
  belongs_to :item
  belongs_to :run
  has_many :meme_items
  has_many :item_relationships, :through => :meme_items
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
      # meme head = meme with max total cosine similarity
      meme_head = nil
      max_cosine_similarity = 0.0
      
      MemeItem.transaction do
        meme.meme_items.each do |mi|
          mi.total_cosine_similarity = mi.item.total_cosine_similarity(run)
          mi.avg_cosine_similarity = mi.item.avg_cosine_similarity(run)
          mi.save
          
          if mi.total_cosine_similarity > max_cosine_similarity
            max_cosine_similarity = mi.total_cosine_similarity
            meme_head = mi.item
          end
        end
        meme.item = meme_head
        meme.save
      end
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
  
  attr_accessor :cached_items
  def items
    if self.cached_items.nil?
      items = Item.find_by_sql(["select distinct i.* from memes m join meme_items mi on mi.meme_id = m.id join item_relationships ir on ir.id = mi.item_relationship_id join items i on i.id = ir.item_id where m.id = ?", self.id])
      self.cached_items = items
      # logger.info "*** I: NOT CACHE"
    else
      # logger.info "*** I: CACHE"
    end
    return self.cached_items
  end
  
  attr_accessor :cached_strength
  def strength
    if self.cached_strength.nil?
      strength = 0
      item_relationships = items = ItemRelationship.find_by_sql(["select ir.* from memes m join meme_items mi on mi.meme_id = m.id join item_relationships ir on ir.id = mi.item_relationship_id where m.id = ?", self.id])
      item_relationships.each do |ir|
        strength += ir.cosine_similarity
      end
      # logger.info "*** S: NOT CACHE"
      self.cached_strength = strength
    else
      # logger.info "*** S: CACHE"
    end
    return self.cached_strength
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
  
end
