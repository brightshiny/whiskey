# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def handle_meme_column_assignment
    
    current_number_of_columns = 0
    current_offset = 0
  
    @memes.each_with_index do |m, c|
      
      next_item = @memes[c+1]
      
      if current_number_of_columns == 0
        m.is_alpha = true
      else 
        m.is_alpha = false
      end
      
      m.number_of_columns = m.z_score_strength.ceil * SiteController::COLUMN_ZOOM_FACTOR
      
      current_number_of_columns += m.number_of_columns
      
      if current_number_of_columns >= (SiteController::MAX_NUMBER_OF_COLUMNS - current_offset) || ((! next_item.nil?)&&((current_number_of_columns + next_item.z_score_strength.ceil*SiteController::COLUMN_ZOOM_FACTOR) > SiteController::MAX_NUMBER_OF_COLUMNS))
        m.number_of_columns += (SiteController::MAX_NUMBER_OF_COLUMNS - current_offset) - current_number_of_columns
        m.break_afterwards = true
        current_number_of_columns = 0
      else
        m.break_afterwards = false
      end        
      
      if c == 1
        current_offset = SiteController::COLUMN_ZOOM_FACTOR
      end
      
    end

  end
  
end
