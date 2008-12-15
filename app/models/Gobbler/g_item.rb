require 'strscan'

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
    return Gobbler::AttrHelper.get_first(@rss_item, [:content, :description, :summary])
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
    Gobbler::GItem.extract_text(@rss_item.title)
  end
  
  def parse_words(db_item)
    content_words = {}
    content = Gobbler::GItem.extract_text(db_item.content)
    content.downcase.scan(/[a-z0-9'\-]+/) {|w| content_words[w] == nil ? content_words[w] = 1 : content_words[w] += 1 }
    
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
            iw.count = content_words[word]
            iw.save
          end
          db_item_words.delete(word)
        else
          iw = ItemWord.new
          iw.word = db_word
          iw.item = db_item
          iw.count = content_words[word]
          iw.save
        end
      end
      
      # catch stragglers, delete
      db_item_words.each_key do |word|
        iw = db_item_words[word]
        iw.delete
      end
    end
  end
  
  def self.extract_text(content) 
    text = []
    return nil if content.nil?
    
    debug_this = false
    state = :text
    prev_state = :text
    entity = []
    tag = []
    
    scanner = StringScanner.new(content)
    while !scanner.eos?
      c = scanner.getch
      
      next if c.nil?
      
      # entity block
      if state != :pre
        if c == '&' && state != :entity
          puts "))) extract_text: entering entity" if debug_this
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
          puts "))) extract_text: exiting entity =[#{entity_text},#{c}]" if debug_this
          state = prev_state
        elsif state == :entity
          
          # bad news, we ran into a tag
          if c == '<'
            puts "))) extract_text: there's a tag in my entity =[#{entity.join}]" if debug_this
            state = prev_state
            text.push "&", entity.join
          else # keep marching on
            puts "))) extract_text: building entity =[#{entity.join}]" if debug_this
            entity.push c
          end
          
          
          # bad news, our tag goes on way too long
          if entity.length >= 7
            entity_text = entity.join
            puts "))) extract_text: my entity is waay toooo large =[#{entity_text}]" if debug_this
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
            puts "))) extract_text: entering pre block" if debug_this
          else
            state = :text
          end
          puts "))) extract_text: exiting html tag, give or take pre" if debug_this
        elsif c == '<'
          state = :html
          tag = []
          puts "))) extract_text: entering html tag" if debug_this
        elsif state == :html
          tag.push c
        elsif state != :html
          text.push c
        end
      end
      
      #puts "))) extract_text: state=#{state.to_s}, prev=#{prev_state.to_s}" if debug_this
      
    end
    
    if debug_this
      puts "))) extract_text input: [#{content}]"
      puts "))) extract_text output: [#{text}]"
    end
    return text.join
  end
  
  
end