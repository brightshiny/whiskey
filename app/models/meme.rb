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
        next if seen_meme_items.has_key?(item.id)
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
  
  def similar_to(prev_meme)
    return false if !prev_meme
    my_items = {}
    prev_meme_items = {}
    
    interesting_items = {296184 => true, 295538 => true, 295587 => true, 295606 => true, 295774 => true, 295572 => true, 295298 => true, 294257 => true, 295293 => true, 295773 => true, 295971 => true, 295427 => true, 295607 => true, 295748 => true, 295285 => true, 292695 => true, 292562 => true, 295857 => true, 295673 => true, 295555 => true, 295630 => true, 29563 => true}
    interesting = true
    
    self.distinct_meme_items.each do |mi|
      item = mi.item_relationship.item
      interesting = true if interesting_items.has_key?(item.id)
      my_items[item.id] = true
      item = mi.item_relationship.related_item
      interesting = true if interesting_items.has_key?(item.id)
      my_items[item.id] = true
    end
    
    prev_meme.distinct_meme_items.each do |mi|
      item = mi.item_relationship.item
      interesting = true if interesting_items.has_key?(item.id)
      prev_meme_items[item.id] = true
      item = mi.item_relationship.related_item
      interesting = true if interesting_items.has_key?(item.id)
      prev_meme_items[item.id] = true
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
    
    #new_item_count = my_items.size
    #lost_item_count = prev_meme_items.size
    
    # pct = (common_item_count.to_f/((new_item_count/4.0).to_f+lost_item_count+common_item_count).to_f).to_f
    if interesting && common_item_count > 2
      return true
      #puts "#{pct} r1=#{self.run.id},m1=#{self.id} vs. r2=#{prev_meme.run.id},m2=#{prev_meme.id} common=#{common_item_count} new=#{new_item_count} lost=#{lost_item_count}"
      #puts %Q(  "#{prev_meme.id}" -> "#{self.id}" [label="#{sprintf('%.2f', pct)} #{common_item_count},#{new_item_count},#{lost_item_count}"];)
    else
      return false
    end
  end
  
  def self.keith    
    
    #    Meme.find(11418).percent_similar_to(Meme.find(11332))
    
    #    start_run_id = 150
    #    end_run_id = 250
    start_run_id = 201
    end_run_id = 250
    prev_run = nil
    
    File.open("doc/a.dot", "w") do |dot|
      dot.puts "digraph whiksey {"
      for run_id in start_run_id .. end_run_id do
        curr_run = Run.find(run_id)
        
        next if curr_run.n != 500 || curr_run.ended_at.nil?
        if curr_run && prev_run
          related_memes = {}
          curr_run.memes.each do |m1|
            prev_run.memes.each do |m2|
              if m1.similar_to(m2)
                related_memes[m1] = m2
              end
            end
          end
          
          related_memes.each do |m1,m2|
            dot.puts %Q(  "#{m1.id}" [label="#{m1.id} (#{sprintf("%.1f", m1.strength)})"];)
            dot.puts %Q(  "#{m2.id}" [label="#{m2.id} (#{sprintf("%.1f", m2.strength)})"];)
          end
          dot.puts %Q(  {rank=same)
          related_memes.keys.each do |m1|
            dot.puts %Q(; #{m1.id})
          end
          dot.puts %Q(  })
          dot.puts %Q(  {rank=same)
          related_memes.values.each do |m2|
            dot.puts %Q(; #{m2.id})
          end
          dot.puts %Q(  })
          related_memes.each do |m1,m2|
            dot.puts %Q(  "#{m2.id}" -> "#{m1.id}";) # [label="#{sprintf('%.2f', pct)} #{common_item_count},#{new_item_count},#{lost_item_count}"];)
          end
          
        end
        prev_run = curr_run
      end
      dot.puts "}"
    end
  end
  
end
