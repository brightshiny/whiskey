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
    min_docs_for_a = 500
    hours_to_scan = 24
    k=nil
    minimum_cosine_similarity = 0.9
    max_matches_per_q = 100
    skip_single_terms = false
    user_id = nil
    
    # spiffy option parsing
    opts = OptionParser.new
    opts.on("-u", "--user-id=USER_ID", "required", Integer) {|val| user_id = val }
    opts.on("-t", "--hours-to-scan=[HOURS]", "defaults to #{hours_to_scan}", Integer) {|val| hours_to_scan = val }
    opts.on("-n", "--max-docs-for-a=[MAX]" "defaults to #{max_docs_for_a}", Integer) {|val| max_docs_for_a = val}
    opts.on("-i", "--min-docs-for-a=[MIN]" "defaults to #{min_docs_for_a}", Integer) {|val| min_docs_for_a = val}
    opts.on("-k", "--k=[K]", "defaults to 2.25 * sqrt(a.size)", Integer) {|val| k=val}
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
    docs = user.documents_from_feeds_by_date_range(start_date-hours_to_scan.hours, start_date, max_docs_for_a, min_docs_for_a)
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    decider.memes({:user => user, :k => k, :n => max_docs_for_a,
      :maximum_matches_per_query_vector => max_matches_per_q, 
      :minimum_cosine_similarity => minimum_cosine_similarity, 
      :skip_single_terms => skip_single_terms, 
      :a => docs, :q => docs, :verbose => false})
  end
  
  def self.calc_meme_stats
    memes = Meme.find(:all, :joins => " as `memes` join runs r on `memes`.run_id = r.id", :conditions => ["`memes`.strength is null and r.ended_at is not null"])
    if memes
      memes.each {|m| Meme.find(m.id).calc_stats }  # dumb, but joins make objects read-only
    end
  end

  attr_accessor :cached_average_meme_strength
  def average_meme_strength
    if ! self.ended_at.nil? && ! self.memes.empty? && self.cached_average_meme_strength.nil?
      self.cached_average_meme_strength = (self.memes.map{ |m| m.strength }.sum / self.memes.size).to_f
    end
    return self.cached_average_meme_strength
  end
  
  attr_accessor :cached_standard_deviation_meme_strength
  def standard_deviation_meme_strength
    if ! self.ended_at.nil? && ! self.memes.empty? 
      total_sq_deviation = self.memes.map{ |m| (self.average_meme_strength - m.strength)**2 }.sum
      self.cached_standard_deviation_meme_strength = (Math.sqrt(total_sq_deviation / self.memes.size)).to_f
    else 
      return 0
    end
    return self.cached_standard_deviation_meme_strength
  end
  
  def generate_meme_relationships(prev_run)
    MemeComparison.transaction do
      meme_comparison = MemeComparison.find(:first, :conditions => ["run_id = ? and related_run_id = ?", self.id, prev_run.id])
      if !meme_comparison
        meme_comparison = MemeComparison.create({:run_id => self.id, :related_run_id => prev_run.id})
      end
      self.memes.each do |m1|
        prev_run.memes.each do |m2|
          if m1.similar_to(m2)
            existing_count = MemeRelationship.count(:conditions => ["meme_comparison_id = ? and meme_id = ? and related_meme_id = ?", meme_comparison.id, m1.id, m2.id])
            if existing_count <= 0
              MemeRelationship.create({:meme_comparison_id => meme_comparison.id, :meme_id => m1.id, :related_meme_id => m2.id})
            end
          end
        end
      end
    end
  end
  
  attr_accessor :cached_published_at_range
  def published_at_range
    if self.cached_published_at_range.nil?
      max_published_at = Time.now - 100.years
      min_published_at = Time.now + 100.years
      self.memes.each { |meme| 
        meme.distinct_meme_items.each { |mi|
          item = mi.item_relationship.item
          max_published_at = item.published_at if max_published_at < item.published_at
          min_published_at = item.published_at if min_published_at > item.published_at
        }
      }
      self.cached_published_at_range = [min_published_at, max_published_at]
    end
    return self.cached_published_at_range
  end
  
  def min_published_at
    published_at_range[0]
  end
  
  def max_published_at
    published_at_range[1]
  end

end


