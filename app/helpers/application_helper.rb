# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def handle_meme_column_assignment
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
    font_size = (meme.z_score_strength ** 0.35).ceil*100
    if font_size == 100 && meme.z_score_strength >= 1
      font_size += 50
    end
    return "#{font_size}%"
  end
  
end
