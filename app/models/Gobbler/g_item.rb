require 'strscan'
require 'stemmer'
include StopWord

class Gobbler::GItem < ActiveRecord::BaseWithoutTable
  
  BASIC_ENTITIES  = {
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
  
  def initialize (rss_item)
    @rss_item = rss_item
  end
  
  def rss_item
    @rss_item
  end
  
  def extract_content
    return nil if @rss_item.nil?
    # guess where the content is...
    return Gobbler::AttrHelper.get_first(@rss_item, [:content_encoded, :content, :description, :summary])
  end
  
  def extract_images(content, pool, item)
    return unless content && pool
    srcs = content.scan(/<img [^>]*src=['"](.*?)['"]/i)[0]
    return unless srcs && srcs.kind_of?(Enumerable)
    for src in srcs.reject{|i| i.match(/(googleadservices.com|feedburner.com)/)}.reject{ |i| i.match(/\s/)}
      pool.push ImageSrc.new(src,item)
    end
    
  end
  
  def extract_published_at
    return nil if @rss_item.nil?
    
    published_at = Gobbler::AttrHelper.get_first(@rss_item, [:published, :pubDate, :dc_date])
    if !published_at.nil?
      return DateTime.parse(published_at.to_s)
    end
    return nil
  end
  
  def extract_title
    Gobbler::GItem.extract_text(@rss_item.title)
  end
  
  def self.parse_words(db_item)
    content_words = {}
    title = Gobbler::GItem.extract_text(db_item.title).strip
    content = Gobbler::GItem.extract_text(db_item.content).strip
    
    if !title || title.size <= 0 || !content || content.length <= 0
      db_item.delete
      logger.info "Parsed item id=#{db_item.id} and deleted it.  Missing title or content."
      return
    end

    content = "#{title} #{content}"
    
    document_word_count = 0
    content.downcase.scan(/[a-z0-9]+/) do |w|
      next if is_stop_word?(w)
      document_word_count += 1
      w = w.stem
      if content_words[w] == nil
        content_words[w] = 1
      else
        content_words[w] += 1
      end
    end

    # load existing db words
    db_words = {}
    existing_words = Word.find(:all, :conditions => ["word in (:words)", {:words => content_words.keys}])
    if !existing_words.nil?
      existing_words.each {|w| db_words[w.word] = w}
    end
    
    # load existing linkages
    db_item_words = {}
    existing_item_words = ItemWord.find(:all, :conditions => ['item_id = :item_id', {:item_id => db_item.id}], :include => :word )
    if !existing_item_words.nil?
      existing_item_words.each do |iw|
        db_item_words[iw.word.word] = iw
      end
    end
    
    # match them all up, create/update/del as needed
    ItemWord.transaction do
      content_words.each_key do |word|
        db_word = nil
        if db_words.has_key?(word)
          db_word = db_words[word]
        else
          db_word = Word.new
          db_word.word = word
          db_word.save
        end
        
        if db_item_words.has_key?(word)
          iw = db_item_words[word]
          if iw.count != content_words[word]
            iw.term_frequency = content_words[word].to_f / document_word_count.to_f
            iw.count = content_words[word]
            iw.save
          end
          db_item_words.delete(word)
        else
          iw = ItemWord.new
          iw.word = db_word
          iw.item = db_item
          iw.count = content_words[word]
          iw.term_frequency = content_words[word].to_f / document_word_count.to_f
          iw.save
        end
      end
      
      # catch stragglers, delete
      db_item_words.each_key do |word|
        iw = db_item_words[word]
        iw.delete
      end
    end
    
    db_item.parsed_at = Time.now
    db_item.word_count = document_word_count
    db_item.save
    logger.info "Parsed item [id=#{db_item.id}]: #{db_item.title}"
  end
  
  def self.extract_text(content) 
    text = []
    return nil if content.nil?
    
    debug_this = false
    state = :text
    prev_state = :text
    entity = []
    tag = []
    
    # goodbye script and embed tags
    content.gsub!(/<\s*(script|embed).*?<\/\1>/i, ' ')
    
    scanner = StringScanner.new(content)
    while !scanner.eos?
      c = scanner.getch
      
      next if c.nil?
      
      logger.info "))) extract_text: state=#{state.to_s}, prev=#{prev_state.to_s}" if debug_this

      # entity block
      if state != :pre
        if c == '&' && state != :entity && state != :html
          logger.info "))) extract_text: entering entity" if debug_this
          prev_state = state
          state = :entity
          entity = []
        elsif state == :entity && c == ';'
          entity_text = entity.join
          m = entity_text.match(/^\#([x\dA-F]{1,5})/)
          if !m.nil? && m.size == 2
            entity_text = m[1].to_i.to_s
          end
          c = BASIC_ENTITIES[entity_text] || ' '
          logger.info "))) extract_text: exiting entity =[#{entity_text},#{c}]" if debug_this
          state = prev_state
        elsif state == :entity
          
          # bad news, we ran into a tag
          if c == '<'
            logger.info "))) extract_text: there's a tag in my entity =[#{entity.join}]" if debug_this
            state = prev_state
            text.push "&", entity.join
          else # keep marching on
            logger.info "))) extract_text: building entity =[#{entity.join}]" if debug_this
            entity.push c
          end
          
          
          # bad news, our tag goes on way too long
          if entity.length >= 7
            entity_text = entity.join
            logger.info "))) extract_text: my entity is waay toooo large =[#{entity_text}]" if debug_this
            c = ''
            text.push "&", entity_text
            state = prev_state
          end
        end
      end
      
      # rest of block
      if state != :entity 
        if state == :html && c == '>'
          if tag.join == "pre"
            state = :pre
            logger.info "))) extract_text: entering pre block" if debug_this
          else
            state = :text
          end
          logger.info "))) extract_text: exiting html tag, give or take pre" if debug_this
        elsif c == '<'
          state = :html
          tag = []
          logger.info "))) extract_text: entering html tag" if debug_this
        elsif state == :html
          tag.push c
        elsif state != :html
          text.push c
        end
      end      
    end
    
    if debug_this
      logger.info "))) extract_text input: [#{content}]"
      logger.info "))) extract_text output: [#{text}]"
    end
    return text.join
  end
  
  
end
