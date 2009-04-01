require 'optparse'

class Run < ActiveRecord::Base
  belongs_to :user
  has_many :item_relationships
  has_many :items, :through => :uber_meme_items
  has_many :uber_memes
  has_many :uber_meme_items
  include Graphviz
  include EncryptedId
  
  def to_s
    "                               db id: #{self.id}
           number_of_documents_for_a: #{self.n}
                                   k: #{self.k}
           minimum_cosine_similarity: #{self.minimum_cosine_similarity}
    maximum_matches_per_query_vector: #{self.maximum_matches_per_query_vector}"
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
    # docs = user.documents_from_feeds_by_date_range(start_date-hours_to_scan.hours, start_date, max_docs_for_a, min_docs_for_a)
    docs = user.recent_documents_from_feeds(max_docs_for_a)
    decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
    decider.memes({:user => user, :k => k, :n => max_docs_for_a,
      :maximum_matches_per_query_vector => max_matches_per_q, 
      :minimum_cosine_similarity => minimum_cosine_similarity, 
      :skip_single_terms => skip_single_terms, 
      :a => docs, :q => docs, :verbose => false})
  end

  attr_accessor :cached_average_meme_strength
  def average_meme_strength
    if ! self.ended_at.nil? && ! self.uber_memes.empty? && self.cached_average_meme_strength.nil?
      self.cached_average_meme_strength = (self.uber_memes.map{ |m| m.strength }.sum / self.uber_memes.size).to_f
    end
    return self.cached_average_meme_strength
  end
  
  attr_accessor :cached_standard_deviation_meme_strength
  def standard_deviation_meme_strength
    if ! self.ended_at.nil? && ! self.uber_memes.empty? && self == Run.current(5) && self.cached_standard_deviation_meme_strength.nil?
      total_sq_deviation = self.uber_memes.map{ |m| (self.average_meme_strength - m.strength)**2 }.sum
      self.cached_standard_deviation_meme_strength = (Math.sqrt(total_sq_deviation / self.uber_memes.size)).to_f
    elsif ! self.ended_at.nil? && ! self.uber_memes.empty? && self != Run.current(5) && self.cached_standard_deviation_meme_strength.nil?
      uber_meme_strengths = UberMeme.find_by_sql(["select um.id, sum(umi.total_cosine_similarity) as calculated_meme_strength from uber_meme_items umi join uber_memes um on um.id = umi.uber_meme_id where umi.run_id = ? group by umi.uber_meme_id order by strength desc", self.id])
      average_meme_strength = uber_meme_strengths.map{ |um| um.calculated_meme_strength.to_f }.sum / uber_meme_strengths.size
      total_sq_deviation = uber_meme_strengths.map{ |um| (average_meme_strength - um.calculated_meme_strength.to_f)**2 }.sum
      self.cached_standard_deviation_meme_strength = (Math.sqrt(total_sq_deviation / uber_meme_strengths.size)).to_f
    end
    return self.cached_standard_deviation_meme_strength
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
  
  attr_accessor :cached_previous_run
  def previous
    if self.cached_previous_run.nil?
      self.cached_previous_run = Run.find(:first, :conditions => ["id < ? and user_id = ? and ended_at is not null", self.id, self.user_id], :order => "id desc")
    end
    return self.cached_previous_run
  end
  
  attr_accessor :cached_next_run
  def next
    if self.cached_next_run.nil?
      self.cached_next_run = Run.find(:first, :conditions => ["id > ? and user_id = ? and ended_at is not null", self.id, self.user_id], :order => "id")
    end
    return self.cached_next_run
  end
  
  def Run.current(user_id)
    @run = Run.find(:first, 
      :conditions => ["user_id = ? and ended_at is not null", user_id],
      :order => "ended_at desc, id desc"
    )
  end
  
  def convert_to_uber_memes
    buckets = []
    cosine_similarities = {}
    
    for ir in self.item_relationships
      doc = Item.find(ir.item_id)
      pdoc = Item.find(ir.related_item_id)
      if doc && pdoc && doc.id != pdoc.id
        #ir = ItemRelationship.create({ :item_id => doc.id, :related_item_id => pdoc.id, :run_id => run.id, :cosine_similarity => pdoc.score }) 
        cosine_similarities[doc.id] = {} unless cosine_similarities.has_key?(doc.id)
        cosine_similarities[doc.id][pdoc.id] = ir.cosine_similarity
        
        still_searching = true
        for bucket in buckets do
          for item_id in bucket.keys do
            if item_id == pdoc.id || item_id == doc.id
              bucket[pdoc.id] = true
              bucket[doc.id] = true
              still_searching = false
              break;
            end
          end
          break if !still_searching
        end
        
        if still_searching
          bucket = {pdoc.id => true, doc.id => true}
          buckets.push bucket
        end
      end
    end
    if buckets.size > 0
      UberMeme.make_memes(:run => self, :buckets => buckets, :cosine_similarities => cosine_similarities)
    end
  end
  
  def self.convert_to_uber_memes
    max_run=Run.find_by_sql("select r.* from runs r where id = (select max(id) as 'cat' from runs where ended_at is not null)").shift
    for i in 1 .. max_run.id
      Run.transaction do
        run = Run.find(i)
        if run && run.ended_at && run.uber_meme_items.size <= 0
          puts "Run #{run.id}"
          run.convert_to_uber_memes
        end
      end
    end
  end

end
