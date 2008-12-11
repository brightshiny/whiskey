require 'simple-rss'
require 'open-uri'
require 'digest/sha1'
require 'cgi'

class Gobbler < ActiveRecord::BaseWithoutTable
  def self.gobble
    gobbler = Gobbler.new
    feeds = []
    if !ARGV.nil? && ARGV.size > 0
      ARGV.each {|id| feeds.push Feed.find(id.to_i) }
    else
      feeds = Feed.find(:all)
    end
    
    feeds.each {|f| gobbler.gobble_feed(f) }
    #  gobbler.extract_words(Item.find(15))
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
      logger.error("Could not get feed: " + e)
    end
    
    begin
      #kmb: why does this not work?
      #rss_title = Gobbler::GItem.extract_text(rss.title)
      
      rss_title = rss.title
      if feed.title.nil? || feed.title != rss_title
        feed.title = rss_title
      end
      
      items_processed = parse_items(feed, rss) || 0
      
      feed.gobbled_at = Time.now
      feed.save
      puts "Processed #{items_processed} items from [id=#{feed.id}]: #{rss_title}"
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
    begin
      rss.items.each do |item|
        gobbler_item = Gobbler::GItem.new(item)
        
        published_at = gobbler_item.extract_published_at
        content = gobbler_item.extract_content
        
        if content.nil? || content.length <= 0
          #logger.info("Unable to extract content from item [#{item.link}], skipping.")
          #pp item
          next
        end
        
        existing = Item.find(:first, :conditions => ["feed_id = :feed_id and link = :link", {:feed_id => feed.id, :link => item.link}])
        if existing.nil?
          existing = Item.new
          existing.feed_id = feed.id
          existing.link = item.link
        end
        
        existing.author = Gobbler::AttrHelper.get_first(item, [:dc_creator])
        existing.published_at = published_at
        existing.content = content
        existing.title = gobbler_item.extract_title
        sha1 = Digest::SHA1.new
        sha1 << content
        existing.content_sha1 = sha1.digest
        existing.save
        items_processed += 1
      end
      
      logger.info("Items processed: " + items_processed.to_s)
    rescue Exception => e
      logger.error("Owie, parsing error: " + e +"\n" + e.backtrace.join("\n"))
    end
    return items_processed
  end
end
