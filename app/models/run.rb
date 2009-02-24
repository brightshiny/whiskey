require 'optparse'

class Run < ActiveRecord::Base
  belongs_to :user
  has_many :item_relationships
  has_many :items, :through => :item_relationships
  has_many :memes
  include Graphviz
  
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
    max_docs_for_a = 500
    hours_to_scan = 24
    k=55
    minimum_cosine_similarity = 0.9
    max_matches_per_q = 100
    skip_single_terms = false
    user_id = nil
    
    # spiffy option parsing
    opts = OptionParser.new
    opts.on("-u", "--user-id=USER_ID", "required", Integer) {|val| user_id = val }
    opts.on("-t", "--hours-to-scan=[HOURS]", "defaults to #{hours_to_scan}", Integer) {|val| hours_to_scan = val }
    opts.on("-n", "--max-docs-for-a=[MAX]" "defaults to #{max_docs_for_a}", Integer) {|val| max_docs_for_a = val}
    opts.on("-k", "--k=[K]", "defaults to 30", Integer) {|val| k=val}
    opts.on("-c", "--minimum-cosine-similarity=[COS]", "defaults to 0.9", Float) {|val| minimum_cosine_similarity = val}
    opts.on("-m", "--max-matches-per-q=[MAX]", "defaults to #{max_matches_per_q}", Integer) {|val| max_matches_per_q = val}
    opts.on("-e", "--environment=[ENV]", "hack for ./script/runner")
    opts.on("-s", "--skip-single-terms") {|val| skip_single_terms = true }
    opts.parse(ARGV)
    
    user = User.find(user_id) if user_id
    if !user_id || !user
      puts "Valid user id required.\n\n#{opts.to_s}"
      return
    end
    
    start_date = Time.now
    most_recent_doc = user.recent_documents_from_feeds(1).first
    if ! most_recent_doc.nil?
      start_date = most_recent_doc.published_at
    end
    docs = user.documents_from_feeds_by_date_range(start_date-hours_to_scan.hours, start_date, max_docs_for_a)
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    decider.memes({:user => user, :k => k, :n => max_docs_for_a,
      :maximum_matches_per_query_vector => max_matches_per_q, 
      :minimum_cosine_similarity => minimum_cosine_similarity, 
      :skip_single_terms => skip_single_terms, 
      :a => docs, :q => docs, :verbose => false})
  end
    
end
