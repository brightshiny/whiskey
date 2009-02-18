require 'fileutils'

module Classy
  module Graphviz
    
    # to use: define run and item_relationships methods
    
    def to_graphviz
      known_items = Hash.new
      
      # how many nodes?
      node_count = 0
      item_relationships.each do |ir|
        known_items[ir.item_id] = true
        known_items[ir.related_item_id] = true
      end
      node_count = known_items.keys.size
      
      # clear known_items
      known_items = Hash.new
      
      # this might be cheating
      run = self if self.instance_of? Run
      
      base_dir="tmp/photo_finish/#{run.id}"
      FileUtils.makedirs(base_dir)
      base_file="#{base_dir}/#{run.id}"
      base_file="#{base_file}-run-#{self.id}-k-#{run.k}-n-#{run.n}"
      File.open("#{base_file}.dot", "w") do |dot|
        dot.puts %Q[digraph "run-#{run.id}-photo" {]
        item_relationships.each do |ir|
          item = ir.item
          for id in [item.id, ir.related_item_id] do
            if !known_items.has_key?(id)
              dot.puts %Q("#{id}" [label="#{id}:#{Item.find(id).title}"];)
              known_items[id] = true
            end
          end
          dot.puts %Q(  "#{ir.item_id}" -> "#{ir.related_item_id}" [label="#{sprintf('%.2f', ir.cosine_similarity)}"];)
        end
        dot.puts "}"
      end
      puts "Generating #{base_file}.png"
      `dot -Tpng "#{base_file}.dot" > "#{base_file}.png"`
    end
    
  end
end