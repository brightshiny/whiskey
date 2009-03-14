require 'simple-rss'
require 'open-uri'
require 'digest/sha1'
require 'cgi'
require 'fileutils'

class Gobbler::Turkey < ActiveRecord::BaseWithoutTable
  attr_reader :decoder

  def initialize
    @decoder = HTMLEntities.new
    super()
  end
  
  def self.fetch
    gobbler = Gobbler::Turkey.new
    feed_id = nil
    user_id = nil
    opts = OptionParser.new
    opts.on("-e", "--environment=[ENV]", "hack for ./script/runner")
    opts.on("-i", "--id=[FEED_ID]", Integer) {|val| feed_id = val }
    opts.on("-u", "--user-id=[USER_ID]", Integer) {|val| user_id = val }
    opts.parse(ARGV)

    user = User.find(user_id) if user_id
    feed = Feed.find(feed_id) if feed_id
    if !feed && !user
      puts "Valid user or feed id required.\n\n#{opts.to_s}"
      return
    end
  
    feeds = []
    if feed
      feeds.push feed
    end
    if user
      feeds += Feed.find(:all, :include => [:users], :conditions => ["`users`.id = ?", user.id])
    end
    
    pool = Gobbler::FeedBag.new(feeds)
    
    threads = (1..GOBBLER_THREAD_COUNT).map do |i|
      Thread.new("consumer #{i}") do |name|
        gobbler = Gobbler::Turkey.new
        while item = pool.get_next
          gobbler.gobble(item,pool)
        end
      end
    end
    
    threads.each do |th|
      begin
        th.join
      rescue RuntimeError => e
        logger.error "Fetch thread failed, rejoining: #{e.backtrace.join("\n\t")}"
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

  def gobble(item,pool)
    begin
      if item.is_a? Feed
        gobble_feed(item,pool)
      elsif item.is_a? ImageSrc
        gobble_image(item)
      else
        warn "I don't know how to gobble this item: #{item}"
      end
    rescue RuntimeError => e
      logger.error "Turkey.gobble() blew up, rescuing. #{e.backtrace.join("\n\t")}"
    end
  end
  
  def gobble_image(image_src)
    image = Image.new
    image.original_src = image_src.src
    image.item_id = image_src.item.id
    image.save
    
    local_path = image_src.local_location_dir(image) 
    local_dir = "#{ITEM_IMAGES_CACHE_DIR}/#{local_path}"
    FileUtils.makedirs(local_dir)
    
    begin
      open(image_src.src) do |f|
        content = f.read
        image_size = ImageSize.new(content)
        image.height = image_size.get_height
        image.width = image_size.get_width
        
        if image.height && image.height > 1 && image.width && image.width > 1 # non-nil, non-tracking
          image.type = image_size.get_type.downcase
          image.local_src = "#{ITEM_IMAGES_SRC}/#{local_path}/#{image.id}.#{image.type}"
          file_name = "#{local_dir}/#{image.id}.#{image.type}"
          File.open(file_name, "w") {|i| i.puts(content) }
          image.save
        else # stupid tracking images
          image.delete
        end
        
      end
    rescue RuntimeError => e
      logger.error "Image download failed (probably harmless): #{e.message}"  #{e.backtrace.join("\n\t")}"
      image.delete
    end
  end
  
  def gobble_feed(feed,pool)
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
      
      if feed.logo.nil?
        host = URI.parse(rss.link.match(/http:\/\/(.*)\/*/)[0]).host
        if !host.nil?
          eater = Gobbler::ImageEater.new(host,feed.id)
          eater.eat_logo
          feed.logo = eater.link
        else
          puts rss.link + " is a chump!"
        end
      end
      
      (items_processed, items_new) = parse_items(feed, rss, pool) || 0
      
      feed.gobbled_at = Time.now
      feed.save
      logger.info "#{Thread.current.object_id}: Processed #{items_processed} (#{items_new} new) items from [id=#{feed.id}]: #{rss_title}"
    rescue Exception => e
      logger.error("Error while processing feed: " + e + "\n" + e.backtrace.join("\n"))  
    end
  end  
  
  def parse_items(feed, rss, pool)
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
        title = gobbler_item.extract_title
       
        # about the length > 255 check:  current varchar size is 255 -- we'll never find anything longer
        # and when we try, we don't use an index and, instead, table scan
        if content.nil? || content.length <= 0 || item.link.nil? || item.link.length > 255
          #logger.info("Unable to extract content or link from item [#{item.link}], skipping.")
          #pp item
          next
        end
        
        #db_item = Item.find(:first, :conditions => ["feed_id = :feed_id and link = :link", {:feed_id => feed.id, :link => item.link}])
        published_before = published_at < 24.hours.ago ? published_at : 24.hours.ago
        db_item = Item.find(:first, :conditions => ["feed_id = :feed_id and title = :title and published_at >= :published_before", 
          {:feed_id => feed.id, :title => title, :published_before => published_before}])
        if db_item.nil?
          db_item = Item.new
          db_item.feed_id = feed.id
          db_item.link = item.link
          db_item.title = title
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
          gobbler_item.extract_images(content, pool, db_item)
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
