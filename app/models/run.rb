require 'optparse'

class Run < ActiveRecord::Base
  has_many :item_relationships
  has_many :items, :through => :item_relationships
  has_many :memes
  include Classy::Graphviz
  
  def to_s
    "                               db id: #{self.id}
           number_of_documents_for_a: #{self.n}
                                   k: #{self.k}
           minimum_cosine_similarity: #{self.minimum_cosine_similarity}
    maximum_matches_per_query_vector: #{self.maximum_matches_per_query_vector}"
  end
  
  def self.to_graphviz
    run_id = nil
    source = "memes"
    opts = OptionParser.new
    opts.on("-iRUN_ID", "--id=RUN_ID") {|val| run_id = val}
    opts.on("-sSOURCE", "--source=SOURCE", "source in [memes,item_relationships], default=memes") { |val| source=val}
    rest = opts.parse(ARGV)
    
    if run_id.nil?
      puts "I didn't understand: " + rest.join(', ') if !rest.nil?
      puts opts.to_s
      return
    end
    
    if !source || (source != "memes" && source != "item_relationships")
      puts "Weird source."
      puts opts.to_s
    end
    
    run = Run.find(run_id)
    
    if source == "memes"
      run.memes.each do |meme|
        meme.to_graphviz    
      end
    else
      run.to_graphviz
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
    
    user = User.find(5) # user named "clone"
    
    puts "Starting run with the following settings: "
    run = Run.create({ :k => k, :n => number_of_documents_for_a, :maximum_matches_per_query_vector => maximum_matches_per_query_vector, :minimum_cosine_similarity => minimum_cosine_similarity, :skip_single_terms => skip_single_terms })
    puts run.to_s
    puts
    
    
    docs = user.recent_documents_from_feeds(run.n)
    run.started_at = Time.now
    run.save
    
    puts "Firing up the classy decider."
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    puts "Getting initial memes from a."
    decider.memes({:run => run, :a => docs, :q => docs, :verbose => false})
    run.ended_at = Time.now
    run.save
    
    # kmb: this is a shortcut for the above run
    # run = Run.find(38)
    
    # puts creating a2
    interesting_docs = {}
    run.memes.each do |meme|
      meme.meme_items.each do |meme_item|
        doc = meme_item.item_relationship.item
        interesting_docs[doc.id] = doc unless interesting_docs.has_key?(doc.id)
        related_doc = meme_item.item_relationship.related_item
        interesting_docs[related_doc.id] = related_doc unless interesting_docs.has_key?(related_doc.id)
      end
    end
    
    # add more interesting docs
    puts "Adding interesting memes/docs to a."
    # kmb: to do
    
    # kmb: here and below is broken
    puts "Processing recent history"    
    # need a new run...
    n = interesting_docs.length
    k = k >= n ? n-1 : k
    q = user.recent_documents_from_feeds(50)
    run2 = Run.create({ :k => k, :n => n, :maximum_matches_per_query_vector => maximum_matches_per_query_vector, :minimum_cosine_similarity => minimum_cosine_similarity, :skip_single_terms => skip_single_terms })
    puts run2
    puts
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    run2.started_at = Time.now
    run2.save
    decider.memes({:run => run2, :a => interesting_docs.values, :q => q, :verbose => true})
    run2.ended_at = Time.now
    run2.save
    
  end
  
  
  
end
