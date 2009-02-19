require 'simple-rss'
require 'open-uri'
require 'digest/sha1'
require 'cgi'

class Gobbler::Turkey < ActiveRecord::BaseWithoutTable
  attr_reader :decoder

  def initialize
    @decoder = HTMLEntities.new
    super()
  end
  
  def self.fetch
    gobbler = Gobbler::Turkey.new
    feeds = []
    ARGV.reject!{ |a| a.match(/^\D/) }
    if !ARGV.nil? && ARGV.size > 0
      ARGV.each {|id| feeds.push Feed.find(id.to_i) }
    else
      feeds = Feed.find(:all)
    end
    
    pool = Gobbler::FeedBag.new(feeds)
    
    threads = (1..GOBBLER_THREAD_COUNT).map do |i|
      Thread.new("consumer #{i}") do |name|
        gobbler = Gobbler::Turkey.new
        while feed = pool.get_next
          gobbler.gobble_feed(feed)
        end
      end
    end
    
    threads.each do |th|
      begin
        th.join
      rescue RuntimeError => e
        logger.error "Fetch thread failed, rejoining: #{e.message}"
      end
    end
  end
  
  def self.parse
    items = []
    ARGV.reject!{ |a| a.match(/^\D/) }
    if !ARGV.nil? && ARGV.size > 0
      ARGV.each do |id|
        feed = Feed.find(id.to_i)
        if !feed.nil?
          feed.items.each {|i| items.push(i)}
        end
      end
    else
      items = Item.find(:all, :conditions => ["parsed_at is null"])
    end
    items.each {|i| Gobbler::GItem.parse_words(i) }
  end
  
  def gobble_feed(feed)
    if feed.nil?
      logger.warn "Can't gobble a nil feed."
      return
    end
    
    logger.info("Gobbling id=#{feed.id} #{feed.link}")
    rss = nil
    begin
      rss = SimpleRSS.parse open(feed.link)
    rescue Exception => e
      logger.error "Could not get feed: " + e
      logger.error "Error trying to download [id=#{feed.id}]: #{e}"
      return
    end
    
    begin
      rss_title = @decoder.decode(rss.title)
      
      if feed.title.nil? || feed.title != rss_title
        feed.title = rss_title
      end
      
       (items_processed, items_new) = parse_items(feed, rss) || 0
      
      feed.gobbled_at = Time.now
      feed.save
      logger.info "#{Thread.current.object_id}: Processed #{items_processed} (#{items_new} new) items from [id=#{feed.id}]: #{rss_title}"
    rescue Exception => e
      logger.error("Error while processing feed: " + e + "\n" + e.backtrace.join("\n"))  
    end
  end  
  
  def parse_items(feed, rss)
    if rss.nil?
      logger.warn "Can't parse_items on a nil feed."
      return
    end
    
    items_processed = 0
    items_new = 0
    begin
      rss.items.each do |item|
        gobbler_item = Gobbler::GItem.new(item)
        
        published_at = gobbler_item.extract_published_at || feed.gobbled_at
        
        content = @decoder.decode(gobbler_item.extract_content)
        
        if content.nil? || content.length <= 0 || item.link.nil?
          #logger.info("Unable to extract content or link from item [#{item.link}], skipping.")
          #pp item
          next
        end
        
        db_item = Item.find(:first, :conditions => ["feed_id = :feed_id and link = :link", {:feed_id => feed.id, :link => item.link}])
        if db_item.nil?
          db_item = Item.new
          db_item.feed_id = feed.id
          db_item.link = item.link
        end
        
        sha1 = Digest::SHA1.new
        sha1 << content.downcase
        digest = sha1.hexdigest
        
        if digest != db_item.content_sha1
          db_item.author = Gobbler::AttrHelper.get_first(item, [:dc_creator])
          db_item.published_at = published_at
          db_item.content = content
          db_item.title = gobbler_item.extract_title
          db_item.content_sha1 = digest
          db_item.parsed_at = nil
          db_item.save
          items_new += 1
        end
        
        items_processed += 1
      end
      
      logger.info("Items processed: " + items_processed.to_s)
    rescue Exception => e
      logger.error("Owie, parsing error: " + e +"\n" + e.backtrace.join("\n"))
    end
    return [items_processed, items_new]
  end
end
