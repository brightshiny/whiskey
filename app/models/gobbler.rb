require 'simple-rss'
require 'open-uri'
require 'digest/sha1'
require 'pp'

class Gobbler
  @logger = Logger.new(STDOUT)
  
  @BASIC_ENTITIES  = {
    'lt' => '<',
    '60' => '<',
    'gt' => '>',
    '62' => '>',
    'apos' => '\'',
    '39' => '\'',
    'quot' => '"',
    '34' => '"',
    'amp' => '&',
    '38' => '&',
    'nbsp' => ' ',
    '160' => ' ',
    'mdash' => '-',
    '8212' => '-',
    'lsquo' => '\'',
    '8216' => '\'',
    'rsquo' => '\'',
    '8217' => '\'',
    'ldquo' => '"',
    '8220' => '"',
    'rdquo' => '"',
    '8221' => '"',
  }
  
  def self.gobble(feed)
    if feed.nil?
      @logger.warn "Can't gobble a nil feed."
      return
    end
    
    @logger.info("Gobbling id=#{feed.id} #{feed.link}")
    rss = nil
    begin
      rss = SimpleRSS.parse open(feed.link)
    rescue Exception => e
      @logger.error("Could not get feed: " + e)
    end
    
    begin
      if feed.title.nil? || feed.title != rss.title
        feed.title = extract_text(rss.title)
      end
      
      parse_items(feed, rss)
      
      feed.gobbled_at = Time.now
      feed.save
      
    rescue Exception => e
      @logger.error("Error while processing feed: " + e)  
    end
    
  end
  
  def self.parse_items(feed, rss)
    if rss.nil?
      @logger.warn "Can't parse_items on a nil feed."
      return
    end
    
    items_processed = 0
    begin
      rss.items.each do |item|
        published_at = extract_published_at(item)
        content = extract_content(item)
        
        if content.nil? || content.length <= 0
          #@logger.info("Unable to extract content from item [#{item.link}], skipping.")
          #pp item
          next
        end
        
        existing = Item.find(:first, :conditions => ["feed_id = :feed_id and link = :link", {:feed_id => feed.id, :link => item.link}])
        if existing.nil?
          existing = Item.new
          existing.feed_id = feed.id
          existing.link = item.link
        end
        
        existing.author = AttrHelper.get_first(item, [:dc_creator])
        existing.published_at = published_at
        existing.content = content
        existing.title = extract_text(item.title)
        sha1 = Digest::SHA1.new
        sha1 << content
        existing.content_sha1 = sha1.digest
        existing.save
        items_processed += 1
      end
      
      @logger.info("Items processed: " + items_processed.to_s)
    rescue Exception => e
      @logger.error("Owie, parsing error: " + e +"\n" + e.backtrace.join("\n"))
    end
  end
  
  def self.extract_content(item)
    if item.nil?
      return nil
    end
    
    # guess where the content is...
    content = AttrHelper.get_first(item, [:content, :description, :summary])
    return extract_text(content)
  end
  
  def self.extract_text(content) 
    return nil if content.nil?
    
    debug_this = false
    state = :text
    prev_state = :text
    entity = ''
    text = ''
    tag = ''
    
    content.each_byte do |b|
      c = b.chr
      
      next if c.nil?
      
      # entity block
      if state != :pre
        if c == '&' && state != :entity
          puts "))) extract_text: entering entity" if debug_this
          prev_state = state
          state = :entity
          entity = ''
        elsif state == :entity && c == ';'
          m = entity.match(/^\#([x\dA-F]{1,5})/)
          if !m.nil? && m.size == 2
            entity = m[1].to_i.to_s
          end
          c = @BASIC_ENTITIES[entity] || ' '
          puts "))) extract_text: exiting entity =[#{entity},#{c}]" if debug_this
          state = prev_state
        elsif state == :entity
          
          # bad news, we ran into a tag
          if c == '<'
            puts "))) extract_text: there's a tag in my entity =[#{entity}]" if debug_this
            state = prev_state
            text += "&#{entity}"
          else # keep marching on
            puts "))) extract_text: building entity =[#{entity}]" if debug_this
            entity += c
          end
          
          
          # bad news, our tag goes on way too long
          if entity.length >= 7
            puts "))) extract_text: my entity is waay toooo large =[#{entity}]" if debug_this
            c = ''
            text += "&#{entity}"
            state = prev_state
          end
        end
      end
      
      # rest of block
      if state != :entity 
        if state == :html && c == '>'
          if tag == "pre"
            state = :pre
            puts "))) extract_text: entering pre block" if debug_this
          else
            state = :text
          end
          puts "))) extract_text: exiting html tag, give or take pre" if debug_this
        elsif c == '<'
          state = :html
          tag = ''
          puts "))) extract_text: entering html tag" if debug_this
        elsif state == :html
          tag += c
        elsif state != :html
          text += c
        end
      end

      #puts "))) extract_text: state=#{state.to_s}, prev=#{prev_state.to_s}" if debug_this

    end

    if debug_this
      puts "))) extract_text input: [#{content}]"
      puts "))) extract_text output: [#{text}]"
    end
    
    return text
  end
  
  def self.extract_published_at(item)
    if item.nil?
      return nil
    end
    
    published_at = AttrHelper.get_first(item, [:published, :pubDate])
    if !published_at.nil?
      return DateTime.parse(published_at.to_s)
    end
    return nil
  end

  
  # kmb: where does this belong?
  Feed.find(:all).each do |feed|
    Gobbler.gobble(feed)
  end
    
#  Gobbler.gobble(Feed.find(3))
  
end
