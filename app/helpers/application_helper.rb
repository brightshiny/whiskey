# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def handle_meme_column_assignment
    
    column_zoom_factor = 4
    max_number_of_columns = 16
    current_number_of_columns = 0
    
    @memes.each_with_index do |m, c|
      
      next_item = @memes[c+1]
      
      if current_number_of_columns == 0
        m.is_alpha = true
      else 
        m.is_alpha = false
      end
      m.number_of_columns = m.z_score_strength.ceil * column_zoom_factor
      current_number_of_columns += m.number_of_columns
      if current_number_of_columns >= max_number_of_columns || ((! next_item.nil?)&&((current_number_of_columns + next_item.z_score_strength.ceil*column_zoom_factor) > max_number_of_columns))
        m.number_of_columns += max_number_of_columns - current_number_of_columns
        m.break_afterwards = true
        current_number_of_columns = 0
      else
        m.break_afterwards = false
      end        
    end

  end
  
end
