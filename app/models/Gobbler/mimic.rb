require 'open-uri'

class Gobbler::Mimic  < ActiveRecord::BaseWithoutTable
  URL = 'http://www.techmeme.com/river'
  
  def self.swim
    f = open(URL)
    c = f.read
    sources = c.scan(/<cite>.*?\s+\/\s+<a href=\"(.*?)\".*?<\/cite>/i).flatten.uniq
    for url in sources
      begin
        f = open(url)
        c = f.read
        links = c.scan(/<link\s+(.*?)\s*rel="alternate"\s*(.*?)>/)
        puts "link check: #{url}"
        for link in links
          link = link.join
          #puts "link check: #{url} #{link}"
          next unless link =~ /type="application\/(rss|atom)\+xml"/
          match_data = link.match(/href="(.*?)"/)
          if match_data
            href = match_data[1]
            href = "#{url}#{href}" if href =~ /^\//
            feed = Feed.find_by_link(href)
            if !feed
              puts "creating #{href}"
              #feed = Feed.create(:link => href)
              #FeedUser.create(:feed_id => feed.id, :user_id => 5)
            end
          end
        end
      rescue
      end
    end
  end
  
end