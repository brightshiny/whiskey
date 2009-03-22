# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def handle_meme_column_assignment
    @has_displayed_level_2 = false
    current_number_of_columns = 0
    @memes.each_with_index do |m, c|
      next_item = @memes[c+1]      
      if current_number_of_columns == 0
        m.is_alpha = true
      else 
        m.is_alpha = false
      end
      m.number_of_columns = m.z_score_strength.ceil * SiteController::COLUMN_ZOOM_FACTOR
      current_number_of_columns += m.number_of_columns
      if current_number_of_columns >= SiteController::MAX_NUMBER_OF_COLUMNS || ((! next_item.nil?)&&((current_number_of_columns + next_item.z_score_strength.ceil*SiteController::COLUMN_ZOOM_FACTOR) > SiteController::MAX_NUMBER_OF_COLUMNS))
        m.number_of_columns += SiteController::MAX_NUMBER_OF_COLUMNS - current_number_of_columns
        m.break_afterwards = true
        current_number_of_columns = 0
      else
        m.break_afterwards = false
      end        
    end
  end
  
  def title_font_size(meme)
    font_size = (meme.z_score_strength ** 0.45).ceil*100
    if font_size == 100 && meme.z_score_strength >= 1
      font_size += 50
    end
    return "#{font_size}%"
  end
  
  def widow_prevention(title)
    (title.gsub(/ (\S+)$/,'&nbsp;\1'))
  end
  
  def link_to_item_with_tracking(*args)
    name         = args.first
    item         = args.second
    options      = args.third || {}
    html_options = args.fourth

    options.merge!({ :controller => :clicks, :action => :create, :i => item.encrypted_id })

    url = url_for(options)
    
    if html_options.nil?
      html_options = {}
    end
    
    title = item.title
    html_options.merge!({ :title => "#{title} | #{item.feed.title}" })
    html_options.merge!({ :onclick => "track_click('#{url}/#{CGI::escape(title)}')"})
    if html_options
      html_options = html_options.stringify_keys
      href = html_options['href']
      convert_options_to_javascript!(html_options, url)
      tag_options = tag_options(html_options)
    else
      tag_options = nil
    end

    href_attr = "href=\"#{item.link.gsub(/\&amp;/,'^^^^^^^^^^').gsub(/\&/,'&amp;').gsub(/\^\^\^\^\^\^\^\^\^\^/,'&amp;')}\"" unless href
    "<a #{href_attr}#{tag_options}>#{name || url}</a>"
  end

  def limit_text(opts={})
    meme = opts[:meme]
    text = opts[:text]
    epsilon = 10
    
    return '' if !meme || !text

    meme_number_of_columns = meme.number_of_columns || 12
    max_col_char_limit = 25 * meme_number_of_columns
    
    truncated = false  
    text = Gobbler::GItem.extract_text(text)
    limited_text = []
    char_count = 0
      for word in text.split
      char_count += (word.size + 1)
      if char_count > max_col_char_limit + epsilon
        truncated = true
        break
      else
        limited_text.push word
      end
    end
    
    truncated_indicator = truncated ? '...' : ''
    last_word = limited_text.pop
    last_word = last_word.chop if !last_word.nil? && !last_word.match(/,$/).nil?
    return "#{limited_text.join(' ')}&nbsp;#{last_word}#{truncated_indicator}"
  end

  def display_date(date)
    date.strftime('%m/%d/%Y').gsub(/^0/,'').gsub(/\/0/,'/')
  end
  def display_time(date)
    date.strftime('%I:%M%p').gsub(/^0/,'').downcase
  end
  
  def meme_strength_trend(meme)
    big_mover_diff = 20 
    minimum_diff = 3 
    s = ""
    if meme.strength_trend != 0
      if meme.strength_trend > 0 && meme.strength_trend > big_mover_diff
        s += "<span class=\"trending trend_up\" title=\"Strength: #{number_with_precision(meme.strength_trend, :precision => 2)}\">&uarr;<span class=\"hide\">+</span></span>"
      elsif meme.strength_trend > 0 && meme.strength_trend > minimum_diff
        s += "<span class=\"trending trend_up\" title=\"Strength: #{number_with_precision(meme.strength_trend, :precision => 2)}\">&uarr;</span>"
      elsif meme.strength_trend < 0 && meme.strength_trend.abs > big_mover_diff
        s += "<span class=\"trending trend_down\" title=\"Strength: #{number_with_precision(meme.strength_trend, :precision => 2)}\">&darr;<span class=\"hide\">-</span></span>"      
      elsif meme.strength_trend < 0 && meme.strength_trend.abs > minimum_diff
        s += "<span class=\"trending trend_down\" title=\"Strength: #{number_with_precision(meme.strength_trend, :precision => 2)}\">&darr;</span>"      
      end
    end
    return s
  end

end
