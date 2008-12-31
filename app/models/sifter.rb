class Sifter < ActiveRecord::BaseWithoutTable
    
  def self.sift_for_all_users
    users = User.find(:all)
    users.each do |u|
      puts "Sifting for user #{u.id}"
      if ! u.nil?
        puts "Generating user document..."
        user_document = u.document_based_on_recently_clicked_items(500) + u.document_based_on_recently_read_items(100)
        puts "Grabbing recent documents index"
        index = Dewey.recent_documents_index
        puts "Getting the 100 most relevent items"
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
        found_items = Item.find(:all, :conditions => ["id in (?)", item_ids], :include => [:feed], :order => "published_at desc")
        found_items.each{ |item| puts "#{item.feed.title.slice(0..30)}) #{item.title.slice(0..60)} (#{item.id})" } 
        puts ""
      else
        puts "Unable to find user #{user_id}"
      end
    end
  end
  
  def self.sift_for_nick_on_december_20
    users = User.find(:all, :conditions => ["id = ?", 1])
    users.each do |u|
      puts "Grabbing recent documents index"
      index = Dewey.recent_documents_index('2008-12-20')
      puts "Sifting for user #{u.id}"
      if ! u.nil?
        puts "Generating user documents..."
        item_ids = []
        recently_clicked_items = Item.find_by_sql("select i.* from items i join clicks c on c.item_id = i.id where c.user_id = #{u.id} and date(c.created_at) <= '2008-12-19'")
        recently_read_items = Item.find_by_sql("select i.* from items i join `reads` r on r.item_id = i.id where r.user_id = #{u.id} and date(r.created_at) <= '2008-12-19' order by r.created_at desc")
        total_items = recently_read_items + recently_clicked_items
        puts "... found #{total_items.size} items"
        # document_made_from_recently_clicked_items = total_items.map{ |i| i.string_of_contained_words }.join(" ")
        # docs = index.find_related(document_made_from_recently_clicked_items, 100)
        # docs.each do |doc| 
        #   encrypted_item_id = doc.match(/^(.*?)\s/)[1]
        #   if ! encrypted_item_id.nil?
        #     item_id = KEY.url_safe_decrypt64(encrypted_item_id)
        #     if ! item_id.nil? 
        #       item_ids.push(item_id)
        #     else
        #       puts "Unable to load item from id (#{item_id})"
        #     end
        #   else
        #     puts "Unable to determine document id"
        #   end
        # end
        total_items.each do |item|
          docs = index.find_related(item.string_of_contained_words, 3)
          docs.each do |doc| 
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
          end
        end
        item_ids.uniq!
        found_items = Item.find(:all, 
          :conditions => ["items.id in (?) and feed_users.user_id = ?", item_ids, u.id], 
          :include => [ :feed ], 
          :joins => "join feed_users on (feed_users.feed_id = feeds.id)",
          :order => "published_at desc"
        )
        
        suggested_items = Item.find(:all, :conditions => ["id in (?)", item_ids])
        
        actual_items = Item.find_by_sql("select i.id from items i join clicks c on c.item_id = i.id where c.user_id = 1 and date(c.created_at) = '2008-12-20' and date(i.published_at) = '2008-12-20'")
        actual_item_ids = actual_items.map{ |i| i.id }

        suggested_and_read = 0
        suggested_and_not_read = 0

        puts ""
        puts "Comparing #{suggested_items.size} suggested items to #{actual_items.size} actual items"

        suggested_items.each do |suggested_item|
          if actual_item_ids.include?(suggested_item.id)
            suggested_and_read += 1
          else
            suggested_and_not_read += 1
          end
        end

        not_suggested_and_read = actual_items.size - suggested_and_read

        puts "Suggested and read:\t#{suggested_and_read}"
        puts "Suggested and not read:\t#{suggested_and_not_read}"
        puts "Not suggested and read:\t#{not_suggested_and_read}"

        puts ""
      else
        puts "Unable to find user #{user_id}"
      end
    end

  end
  
  def self.sift_for_all_users_new_technique
    users = User.find(:all)
    users.each do |u|
      puts "Grabbing recent documents index"
      index = Dewey.recent_documents_index
      puts "Sifting for user #{u.id}"
      if ! u.nil?
        puts "Generating user documents..."
        item_ids = []
        u.recently_clicked_items(100).each do |item|
          docs = index.find_related(item.string_of_contained_words, 3)
          docs.each do |doc| 
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
          end
        end
        item_ids.uniq!
        found_items = Item.find(:all, 
          :conditions => ["items.id in (?) and feed_users.user_id = ?", item_ids, u.id], 
          :include => [ :feed ], 
          :joins => "join feed_users on (feed_users.feed_id = feeds.id)",
          :order => "published_at desc"
        )
        found_items.each{ |item| puts "#{item.feed.title.slice(0..30)}) #{item.title.slice(0..60)} (#{item.id})" } 
        puts ""
      else
        puts "Unable to find user #{user_id}"
      end
    end
  end
  
end
