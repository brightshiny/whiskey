class Gobbler::GItem
  
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
    content = Gobbler::AttrHelper.get_first(@rss_item, [:content, :description, :summary])
    return extract_text(content)
  end  
  
  def extract_published_at
    return nil if @rss_item.nil?
    
    published_at = Gobbler::AttrHelper.get_first(@rss_item, [:published, :pubDate])
    if !published_at.nil?
      return DateTime.parse(published_at.to_s)
    end
    return nil
  end
  
  def extract_title
    extract_text(@rss_item.title)
  end
  
  def extract_words
    content_words = {}
    @rss_item.content.downcase.scan(/[a-z0-9'\-]+/) {|w| content_words[w] == nil ? content_words[w] = 1 : content_words[w] += 1 }
    
    # create any missing db words
    existing_words = {}
    db_words = Word.find(:all, :conditions => ["word in (:words)", {:words => content_words.keys}])
    
    if !db_words.nil?
      db_words.each {|w| existing_words[w.word] = w}
    end
    
    content_words.each_key do |content_word|
      w = nil
      if existing_words.has_key?(content_word)
        w = existing_words[content_word]
      else
        w = Word.new
        w.word = content_word
        w.save
      end
      
      #kmb: come back later and make this less brute force      
    end
    
  end
  
  def extract_text(content) 
    text = ''
    return nil if content.nil?
    
    debug_this = false
    state = :text
    prev_state = :text
    entity = ''
    tag = ''
    
    #kmb: use string scanner.getch
    content.each_byte do |b|
      c = b.chr
      
      next if c.nil?
      
      # entity block
      if state != :pre
        #kmb: check to see if we're in an anchor tag (or html in general?)
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
          c = BASIC_ENTITIES[entity] || ' '
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
  
  
end