class Dewey < ActiveRecord::BaseWithoutTable

  # 
  # I highly suggest installing rb-gsl (via MacPorts if you like)
  # It's much faster than the native Ruby LSI methods
  # 

  @@recent_documents_index = nil
  
  def self.recent_documents_index
    if @@recent_documents_index.nil?
      puts "Index has not been built yet"
      puts "Building now..."
      index = Classifier::LSI.new
      items = Item.recent_items(500)
      items.each{ |i| index.add_item "#{KEY.url_safe_encrypt64(i.id)} #{i.string_of_contained_words}" }
      # items.each do |item|
      #   if ! item.nil? && ! item.string_of_contained_words.nil? && ! item.string_of_contained_words.empty? && item.string_of_contained_words.size > 0
      #     index.add_item item { |i| i.string_of_contained_words } 
      #   end
      # end
      puts "... done building index"
      @@recent_documents_index = index
    end
    return @@recent_documents_index
  end

end
