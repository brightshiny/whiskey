require 'simple-rss'
require 'open-uri'
require 'digest/sha1'
require 'cgi'

class Gobbler::Turkey < ActiveRecord::BaseWithoutTable
  def self.gobble
    gobbler = Gobbler::Turkey.new
    feeds = []
    ARGV.reject!{ |a| a.match(/^\D/) }
    if !ARGV.nil? && ARGV.size > 0
      ARGV.each {|id| feeds.push Feed.find(id.to_i) }
    else
      feeds = Feed.find(:all)
    end
    
    feeds.each {|f| gobbler.gobble_feed(f) }
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
      puts "Error trying to download [id=#{feed.id}]: #{e}"
      return
    end
    
    begin
      rss_title = Gobbler::GItem.extract_text(rss.title)
      
      if feed.title.nil? || feed.title != rss_title
        feed.title = rss_title
      end
      
       (items_processed, items_new) = parse_items(feed, rss) || 0
      
      feed.gobbled_at = Time.now
      feed.save
      puts "Processed #{items_processed} (#{items_new} new) items from [id=#{feed.id}]: #{rss_title}"
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
        
        published_at = gobbler_item.extract_published_at
        content = gobbler_item.extract_content
        
        if content.nil? || content.length <= 0
          #logger.info("Unable to extract content from item [#{item.link}], skipping.")
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
        sha1 << content
        digest = sha1.hexdigest
        
        if digest != db_item.content_sha1
          db_item.author = Gobbler::AttrHelper.get_first(item, [:dc_creator])
          db_item.published_at = published_at
          db_item.content = content
          db_item.title = gobbler_item.extract_title
          db_item.content_sha1 = digest
          db_item.save
          # engage parsing magic
          gobbler_item.parse_words(db_item)
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
