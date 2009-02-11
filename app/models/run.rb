require 'fileutils'
require 'optparse'

class Run < ActiveRecord::Base
  has_many :item_relationships
  has_many :items, :through => :item_relationships
  has_many :memes
  
  def to_s
    "                               db id: #{self.id}
           number_of_documents_for_a: #{self.n}
                                   k: #{self.k}
           minimum_cosine_similarity: #{self.minimum_cosine_similarity}
    maximum_matches_per_query_vector: #{self.maximum_matches_per_query_vector}"
  end
  
  def self.to_graphviz
    run_id = nil
    opts = OptionParser.new
    opts.on("-iRUN_ID", "--id=RUN_ID") {|val| run_id = val}
    rest = opts.parse(ARGV)
    if run_id.nil?
      puts "I didn't understand: " + rest.join(', ') if !rest.nil?
      puts opts.to_s
      return
    end
    
    run = Run.find(run_id)
    run.memes.each do |meme|
      meme.to_graphviz    
    end
    
  end
  
  def self.go
    # defaults
    number_of_documents_for_a = 200
    k=30
    minimum_cosine_similarity = 0.9
    maximum_matches_per_query_vector = 100
    skip_single_terms = false
    
    # spiffy option parsing
    opts = OptionParser.new
    opts.on("-n[SIZE_OF_A]", "--number-of-documents-for-a=[SIZE_OF_A]" "defaults to 100", Integer) {|val| number_of_documents_for_a = val}
    opts.on("-k[K]", "--k=[K]", "defaults to 30", Integer) {|val| k=val}
    opts.on("-c[COS]", "--minimum-cosine-similarity=[COS]", "defaults to 0.9", Float) {|val| minimum_cosine_similarity = val}
    opts.on("-m[MATCHES]", "--maximum-matches-per-query-vector=[MATCHES]", "defaults to 20", Integer) {|val| maximum_matches_per_query_vector = val}
    opts.on("-s", "--skip-single-terms") {|val| skip_single_terms = true }
    opts.parse(ARGV)
    
    puts "Starting run with the following settings: "
    run = Run.create({ :k => k, :n => number_of_documents_for_a, :maximum_matches_per_query_vector => maximum_matches_per_query_vector, :minimum_cosine_similarity => minimum_cosine_similarity, :skip_single_terms => skip_single_terms })
    puts run.to_s
    puts
    
    user = User.find(5) # user named "clone"
    
    consumed_docs = user.recent_documents_from_feeds(run.n)
    run.started_at = Time.now
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    decider.matrix.add_to_a(consumed_docs)
    run.distinct_term_count = decider.matrix.max_term_index
    run.save
    
    # magic in-memory data structure for meme processing
    relationship_map = {}
    
    consumed_docs.each_with_index { |doc, i| 
      puts "\n#{doc.title}\n"    
      predicted_docs = decider.process_q([doc], run.minimum_cosine_similarity, run.k, run.maximum_matches_per_query_vector, run.skip_single_terms)
      total_score = 0
      predicted_docs.each { |pdoc|
        if doc.id == pdoc.id
          puts "\t(skipped) %1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]
        else
          puts "\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]
          ir = ItemRelationship.create({ :item_id => doc.id, :related_item_id => pdoc.id, :run_id => run.id, :cosine_similarity => pdoc.score }) 
          relationship_map[ir.item_id] = Array.new unless relationship_map.has_key?(ir.item_id)
          relationship_map[ir.item_id].push(ir)
          total_score += pdoc.score
        end
      }
      puts "\tTotal Score: #{total_score} (#{total_score.to_f / predicted_docs.size.to_f} avg)"
    }
    # generate memes!
    Meme.memes_from_item_relationship_map(run, relationship_map, true)
    run.ended_at = Time.now
    run.save
  end
  
end
