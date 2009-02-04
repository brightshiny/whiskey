require 'fileutils'

class Run < ActiveRecord::Base
  has_many :item_relationships
  has_many :items, :through => :item_relationships
  has_many :memes
  
  def self.photo_finish
    ARGV.reject!{ |a| a.match(/^(ENV|\-)/) } # stupid ENV params                                                                                                                 
    if ARGV.size != 1
      puts "I need one run id, please."
      return -1
    end
    
    puts " Generating pretty pictures for run:"
    run = Run.find(ARGV[0])
    puts run.to_s
    puts
    
    relationships = ItemRelationship.find(:all, :conditions => ["run_id = ? and cosine_similarity < 1", run.id])
    puts "Sifting through #{relationships.size} relationships"

    # generate my magic in-memory data structure for processing
    relationship_map = {}
    relationships.each do |r|
      relationship_map[r.item_id] = Array.new unless relationship_map.has_key?(r.item_id)
      relationship_map[r.item_id].push(r)
    end
    
    # take_photo(run, relationship_map, "0-panorama")
    take_flash_photo(run, relationship_map, "0-panorama")
    Meme.memes_from_item_relationship_map(run, relationship_map, true)    
  end
  
  def self.take_photo(run, relationship_map, name)
    base_dir="tmp/photo_finish/#{run.id}"
    FileUtils.makedirs(base_dir)
    # make overall (panorama) png
    base_file="#{base_dir}/#{run.id}"
    panorama_file="#{base_file}-#{name}"
    File.open("#{panorama_file}.dot", "w") do |dot|
      dot.puts %Q[digraph "run-#{run.id}-photo" {]
      relationship_map.each do |item_id, relations|
        item = Item.find(item_id)
        dot.puts %Q("#{item_id}" [label="#{item_id}:#{item.title.gsub(/\W/,'')}"];)
        relations.each do |r|
          dot.puts %Q(  "#{r.item_id}" -> "#{r.related_item_id}" [label="#{sprintf('%.2f', r.cosine_similarity)}"];)
        end
      end
      dot.puts "}"
    end
    puts "Generating #{panorama_file}.png"
    `dot -Tpng "#{panorama_file}.dot" > "#{panorama_file}.png"`
  end
  
  # def self.take_flash_photo(run, relationship_map, name)
  #   base_dir="tmp/photo_finish/#{run.id}"
  #   FileUtils.makedirs(base_dir)
  #   
  #   # make overall (panorama) png
  #   base_file="#{base_dir}/#{run.id}"
  #   panorama_file="#{base_file}-#{name}"
  #   File.open("#{panorama_file}.xml", "w") do |dot|
  #     dot.puts '<?xml version="1.0"?>'
  #     dot.puts '<graph title="Whiskey Test" bgcolor="ffffff" linecolor="cccccc" viewmode="explore" width="600" height="300">'
  #     nodes = []
  #     edges = []
  #     relationship_map.each do |item_id, relations|
  #       item = Item.find(item_id)
  #       # dot.puts %Q("#{item_id}" [label="#{item_id}:#{item.title.gsub(/\W/,'')}"];)
  #       nodes.push("<node id=\"n#{item.id}\" text=\"#{item.title.gsub(/\W/,' ')}\" type=\"CircleNode\" link=\"#{item.link}\" scale=\"120\" color=\"0000ff\" textcolor=\"0000ff\"/>")
  #       relations.each do |r|
  #         # dot.puts %Q(  "#{r.item_id}" -> "#{r.related_item_id}" [label="#{sprintf('%.2f', r.cosine_similarity)}"];)
  #         edges.push("<edge sourceNode=\"n#{r.item_id}\" targetNode=\"n#{r.related_item_id}\" label=\"#{sprintf('%.2f', r.cosine_similarity)}\" textcolor=\"555555\"/>")
  #       end
  #     end
  #     dot.puts nodes.join("\n")
  #     dot.puts edges.join("\n")
  #     dot.puts "</graph>"
  #     # dot.puts "}"
  #   end
  # 
  #   # puts "Generating #{panorama_file}.png"
  #   # `dot -Tpng "#{panorama_file}.dot" > "#{panorama_file}.png"`
  # end

  def self.take_flash_photo(run, relationship_map, name)
    base_dir="tmp/photo_finish/#{run.id}"
    FileUtils.makedirs(base_dir)
    base_file="#{base_dir}/#{run.id}"
    panorama_file="#{base_file}-#{name}"
    File.open("#{panorama_file}.graphml", "w") do |dot|
      puts "Generating #{panorama_file}.graphml"
      dot.puts '<?xml version="1.0" encoding="UTF-8"?>'
      dot.puts '<!DOCTYPE graphml SYSTEM "http://www.graphdrawing.org/dtds/graphml.dtd"><graphml>'
      dot.puts '<key id="d1" for="edge" attr.name="weight" attr.type="double"/>'
      dot.puts '<key id="name" for="node" attr.name="name" attr.type="string"/>'
      dot.puts '<key id="link" for="node" attr.name="link" attr.type="string"/>'
      dot.puts '<key id="item_id" for="node" attr.name="item_id" attr.type="integer"/>'
      dot.puts '<graph id="animalValues-05" edgedefault="undirected" clipContent="false">'
      nodes = []
      edges = []
      already_included_edges = {}
      relationship_map.each do |item_id, relations|
        item = Item.find(item_id)
        nodes.push("<node id=\"#{item.id}\"><data key=\"link\">#{item.link}</data><data key=\"name\">#{item.title.gsub(/\W/,' ')}</data><data key=\"item_id\">#{item.id}</data></node>")
        relations.each do |r|
          if already_included_edges[r.item_id].nil? || ! already_included_edges[r.item_id].include?(r.related_item_id)
            related_item = Item.find(r.related_item_id)
            edges.push("<edge source=\"#{item.id}\" target=\"#{related_item.id}\"><data key=\"d1\">#{1.0 / (r.cosine_similarity * r.cosine_similarity)}</data></edge>")
            if already_included_edges[r.item_id].nil?
              already_included_edges[r.item_id] = [r.related_item_id]
            else
              already_included_edges[r.item_id].push(r.related_item_id)
            end
            if already_included_edges[r.related_item_id].nil?
              already_included_edges[r.related_item_id] = [r.item_id]
            else
              already_included_edges[r.related_item_id].push(r.item_id)
            end
          end
        end
      end
      dot.puts nodes.join("\n")
      dot.puts edges.join("\n")
      dot.puts "</graph></graphml>"
    end
  end
  
  def to_s
    "                               db id: #{self.id}
           number_of_documents_for_a: #{self.n}
                                   k: #{self.k}
           minimum_cosine_similarity: #{self.minimum_cosine_similarity}
    maximum_matches_per_query_vector: #{self.maximum_matches_per_query_vector}"
  end
  
  def self.on_your_mark_get_set_go
    ARGV.reject!{ |a| a.match(/^(ENV|\-)/) } # stupid ENV params                                                                                                                 
    if ARGV.size != 0 && ARGV.size != 4
      puts "You must call 'on_your_marks_get_set_go' thusly: "
      puts "\nscript/runner Run.on_your_marks_get_set_go 1 2 3 4"
      puts "\nWhere:\n\t1 is the number of documents for a\n\t2 is k\n\t3 is minimum cosine similarity\n\t4 is maximum docs returned"
    else
      number_of_documents_for_a = ARGV[0].nil? ? 100 : ARGV[0].to_i
      k = ARGV[1].nil? ? 30 : ARGV[1].to_i
      minimum_cosine_similarity = ARGV[2].nil? ? 0.9 : ARGV[2].to_f
      maximum_matches_per_query_vector = ARGV[3].nil? ? 20 : ARGV[3].to_i
      
      puts "Starting run with the following settings: "
      run = Run.create({ :k => k, :n => number_of_documents_for_a, :maximum_matches_per_query_vector => maximum_matches_per_query_vector, :minimum_cosine_similarity => minimum_cosine_similarity })
      puts run.to_s
      puts
      
      user = User.find(5) # user named "clone"
      
      consumed_docs = user.recent_documents_from_feeds(number_of_documents_for_a)
      decider = Classy::Decider.new
      decider.add_to_a(consumed_docs)
      
      consumed_docs.each_with_index { |doc, i| 
        puts "\n#{doc.title}\n"    
        predicted_docs = decider.enhanced_process_q([doc], run.minimum_cosine_similarity, run.k, run.maximum_matches_per_query_vector)
        total_score = 0
        predicted_docs.each { |pdoc|
          puts "\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]          
          ir = ItemRelationship.create({ :item_id => doc.id, :related_item_id => pdoc.id, :run_id => run.id, :cosine_similarity => pdoc.score }) 
          total_score += pdoc.score
        }
        puts "\tTotal Score: #{total_score} (#{total_score.to_f / predicted_docs.size.to_f} avg)"
      }
    end
  end
  
end
