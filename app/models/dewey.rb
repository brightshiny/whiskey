class Dewey < ActiveRecord::BaseWithoutTable

  # 
  # I highly suggest installing rb-gsl (via MacPorts if you like)
  # It's much faster than the native Ruby LSI methods
  # 

  @@recent_documents_index = nil
  
  def self.recent_documents_index
    if @@recent_documents_index.nil?
      puts "Index has not been built yet"
      start_time = Time.now
      puts "Building now... (#{start_time})"
      index = Classifier::LSI.new :auto_rebuild => false
      # index = Classifier::LSI.new
      items = Item.recent_items(500)
      items.each do |i| 
        index.add_item "#{KEY.url_safe_encrypt64(i.id)} #{i.string_of_contained_words}" 
      end
      index.build_index(0.75)
      end_time = Time.now
      puts "... done building index (#{end_time})"
      puts "Index creation took #{end_time - start_time} seconds"
      @@recent_documents_index = index
    end
    return @@recent_documents_index
  end

end
