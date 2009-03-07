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
    html_options.merge!({ :title => "#{item.title} #{item.link}" })
    
    if html_options
      html_options = html_options.stringify_keys
      href = html_options['href']
      convert_options_to_javascript!(html_options, url)
      tag_options = tag_options(html_options)
    else
      tag_options = nil
    end

    href_attr = "href=\"#{url}\"" unless href
    "<a #{href_attr}#{tag_options}>#{name || url}</a>"
  end

  
end
