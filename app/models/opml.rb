class Opml < ActiveRecord::BaseWithoutTable
  
  attr_accessor :content, :feed_uris
   
  def self.new_from_file(filename)
    o = self.new
    o.content = File.read(filename)
    return o
  end

  def parse_for_feed_uris
    @feed_uris = content.scan(/xmlUrl\=\"(.*?)\"/).flatten.uniq 
  end

  def create_or_update_uris_from_array_of_feeds(user=nil)
    if @feed_uris.nil?
      self.parse_for_feed_uris
    end
    @feed_uris.each{ |feed_uri|
      if feed_uri.match(/^h/)
        Feed.transaction do 
          feed = Feed.find_or_create_by_link(feed_uri)
          if ! user.nil?
            begin
              if FeedUser.find(:first, :conditions => ["feed_id = ? and user_id = ?", feed.id, user.id]).nil?
                FeedUser.create({ :feed_id => feed.id, :user_id => user.id })
              end
            rescue
              logger.info "Relationship already existed or unable to establish relationship between user #{user.id} and feed #{feed.id}"
            end
          end
        end
      end
    }
  end
  
end
