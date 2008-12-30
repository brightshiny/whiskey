class Sifter < ActiveRecord::BaseWithoutTable
    
  def self.sift_for_user 
    user_id = ARGV[0]
    2.times do |n|
      puts "Sifting for user #{user_id}"
      u = User.find(:first, :conditions => ["id = ?", user_id])
      if ! u.nil?
        puts "Generating user document..."
        user_document = u.document_based_on_recently_clicked_items + u.document_based_on_recently_read_items
        puts "Grabbing recent documents index"
        index = Dewey.recent_documents_index
        puts "Getting the 10 most relevent items"
        docs = index.find_related(user_document, 100)
        item_ids = []
        docs.each { |doc| 
          encrypted_item_id = doc.match(/^(.*?)\s/)[1]
          if ! encrypted_item_id.nil?
            item_id = KEY.url_safe_decrypt64(encrypted_item_id)
            if ! item_id.nil? 
              item_ids.push(item_id)
            else
              puts "Unable to load item from id (#{item_id})"
            end
          else
            puts "Unable to determine document id"
          end
        }
        item_ids.uniq!
        found_items = Item.find(:all, :conditions => ["id in (?)", item_ids])
        found_items.each{ |item| puts "#{item.id}) #{item.title.slice(0..60)}" } 
        puts ""
      else
        puts "Unable to find user #{user_id}"
      end
    end
  end
    
end
