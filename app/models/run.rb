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
    docs = user.recent_documents_from_feeds(number_of_documents_for_a)
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    decider.memes({:k => k, :n => number_of_documents_for_a,
      :maximum_matches_per_query_vector => maximum_matches_per_query_vector, 
      :minimum_cosine_similarity => minimum_cosine_similarity, 
      :skip_single_terms => skip_single_terms, 
      :a => docs, :q => docs, :verbose => false})
  end
  
  def self.plan_a
    # 1) R1 = 100 items (A1)  -- this is run.id = 4
    # 2) Create M's from R1 items (A1) -- also run.id = 4
    # 3) A2 = Combine items from M's in A1 made via R1.
    # 4) R2 = next 50 items as q against A2
    
    # create q: all the items from run 6 (n=200), which includes 100 items from run 4 (n=100)
    q = User.find(5).recent_documents_from_feeds(200)
    
    r1 = Run.find(4)
    # creating a2
    a2 = {}
    r1.memes.each do |meme|
      meme.meme_items.each do |meme_item|
        doc = meme_item.item_relationship.item
        a2[doc.id] = doc unless a2.has_key?(doc.id)
        #q.delete(doc.id)
        related_doc = meme_item.item_relationship.related_item
        a2[related_doc.id] = related_doc unless a2.has_key?(related_doc.id)
        #q.delete(related_doc.id)
      end
    end
    
    # add more interesting docs to a2
    # kmb: to do
    
    # kmb: here and below is broken
    puts "Processing recent history"
    # need a new run...
    
    decider = Classy::Decider.new(:skip_single_terms => r1.skip_single_terms)
    decider.memes({ :k => 30, :n => a2.size, 
      :maximum_matches_per_query_vector => r1.maximum_matches_per_query_vector,
      :minimum_cosine_similarity => r1.minimum_cosine_similarity, 
      :skip_single_terms => r1.skip_single_terms, 
      :a => a2.values, :q => q, :verbose => true})
    
    # lastly, copy item relationships from initial run over to r2 -- they should overlay with r2's items relationships
    r1.item_relationships.each do |ir|
      ItemRelationship.create({:run => r2, :item => ir.item, :related_item => ir.related_item, :cosine_similarity => ir.cosine_similarity})
    end
  end
  
  def self.plan_b
    # 1-4 are same as plan_a
    # 1) R1 = 100 items (A1)  -- this is run.id = 4
    # 2) Create M's from R1 items (A1) -- also run.id = 4
    # 3) A2 = Combine items from M's in A1 made via R1.
    # 4) R2 = next 50 items as q against A2
    # 5) A3 = item relationships from R1 and R2
    # 6) R3 = standard run where (A3=Q)
    
    # create q: all the items from run 6 (n=200), which includes 100 items from run 4 (n=100)
    q = User.find(5).recent_documents_from_feeds(200)
    
    r1 = Run.find(4)
    # creating a2
    a2 = {}
    r1.memes.each do |meme|
      meme.meme_items.each do |meme_item|
        doc = meme_item.item_relationship.item
        a2[doc.id] = doc unless a2.has_key?(doc.id)
        related_doc = meme_item.item_relationship.related_item
        a2[related_doc.id] = related_doc unless a2.has_key?(related_doc.id)
      end
    end
    
    # add more interesting docs to a2
    # kmb: to do
    
    # kmb: here and below is broken
    puts "Processing recent history"
    # need a new run...
    
    decider = Classy::Decider.new(:skip_single_terms => r1.skip_single_terms)
    r2 = decider.memes({:k => 30, :n => a2.size, :maximum_matches_per_query_vector => r1.maximum_matches_per_query_vector, :minimum_cosine_similarity => r1.minimum_cosine_similarity, :a => a2.values, :q => q, :verbose => false})
    
    # copy item relationships from initial run over to r2 -- they should overlay with r2's items relationships
    r1.item_relationships.each do |ir|
      ItemRelationship.create({:run => r2, :item => ir.item, :related_item => ir.related_item, :cosine_similarity => ir.cosine_similarity})
    end
    
    # create a3 as items from r1 and r2.  r2 contains item_relationships from r1, so we'll just look at r2
    docs = Item.find(:all, 
                     :conditions => ["irs.run_id = ?", r2.id], 
    :joins => "join item_relationships irs on (irs.related_item_id = `items`.id or irs.item_id = `items`.id)"
    )
    
    a3 = {}
    docs.each {|d| a3[d.id] = d unless a3.has_key?(d.id) }
    
    
    decider = Classy::Decider.new(:skip_single_terms => r1.skip_single_terms)
    # r3 = 
    decider.memes({:k => r1.k, :n => a3.size, :maximum_matches_per_query_vector => r1.maximum_matches_per_query_vector, :minimum_cosine_similarity => r1.minimum_cosine_similarity, :skip_single_terms => r1.skip_single_terms, :a => a3.values, :q => a3.values, :verbose => false})
  end
  
end
