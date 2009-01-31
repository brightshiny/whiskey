class Meme < ActiveRecord::Base
  belongs_to :item
  belongs_to :run
  has_many :meme_items
  has_many :item_relationships, :through => :meme_items
  
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
        lead_item_id = ir_map.keys.shift
        lead_item = Item.find(lead_item_id)
        meme.item = lead_item
        meme.run = run
        meme.save
        
        # generate an ir_map, a hash[item_id] of arrays[item_relationships]
        meme_ir_map = meme_from_map(lead_item_id, ir_map)
        # Run.take_photo(run, meme_ir_map, "#{lead_item.id}-#{meme_ir_map.keys.size}-nodes")
        Run.take_flash_photo(run, meme_ir_map, "#{lead_item.id}-#{meme_ir_map.keys.size}-nodes")
        
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
      items = []
      self.item_relationships.each do |ir|
        items.push ir.item
      end
      items.uniq!
      self.cached_items = items
    end
    return self.cached_items
  end
  
end
