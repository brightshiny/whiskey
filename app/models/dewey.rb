class Dewey < ActiveRecord::BaseWithoutTable

  # 
  # I highly suggest installing rb-gsl (via MacPorts if you like)
  # It's much faster than the native Ruby LSI methods
  # 

  @@recent_documents_index = nil
  
  def self.recent_documents_index(date_of_interest = nil)
    if @@recent_documents_index.nil?
      puts "Index has not been built yet"
      start_time = Time.now
      puts "Building now... (#{start_time})"
      index = Classifier::LSI.new :auto_rebuild => false
      # if date_of_interest.nil?
      #   items = Item.recent_items(500)
      # else
      #   # items = Item.find(:all, :conditions => ["date(created_at) = ?", date_of_interest], :include => [ :words ], :order => "published_at desc", :limit => 1500)
        items = Item.find_by_sql("select i.* from items i join feeds f on f.id = i.feed_id join feed_users fu on fu.feed_id = f.id where fu.user_id = 1 and date(i.created_at) = '2008-12-20'")
      # end
      puts "\tAdding #{items.size} documents..."
      items.each do |i| 
        index.add_item "#{KEY.url_safe_encrypt64(i.id)} #{i.string_of_contained_words}" 
      end
      puts "\t... done adding docs"
      accuracy_measure = 0.80
      puts "\tBuilding very large and scary matrix... (#{accuracy_measure})"
      index.build_index(accuracy_measure)
      puts "\t... matrix sufficiently scary"
      end_time = Time.now
      puts "... done building index (#{end_time})"
      puts "Index creation took #{end_time - start_time} seconds"
      @@recent_documents_index = index
    end
    return @@recent_documents_index
  end

end
