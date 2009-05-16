class TwitterClient
  
  def self.send_item(uber_meme)
    res = Net::HTTP.post_form(URI.parse('http://pnt.me/links/c'), {'link[destination]'=>"http://refinr.com/site/meme/#{uber_meme.id}"})
    if res.response.code == "200" && res.body.match(/^http/) && res.body.size < 25
      puts "Tweeting: #{c.body_str}"
      link = res.body          
      httpauth = Twitter::HTTPAuth.new('refinr', '9aHefafaXath')
      base = Twitter::Base.new(httpauth)
      text = "News: #{uber_meme.item.title[0..110]}"
      if uber_meme.item.title.size > 110
        text += "..."
      end
      base.update("#{text} #{link}")
    else
      puts "Tweeting Failed: #{res.response.code}"
    end
  end
  
  def self.send_private(text)
    httpauth = Twitter::HTTPAuth.new('refinr_private', '9aHefafaXath')
    base = Twitter::Base.new(httpauth)
    base.update(text)
    puts "Private Tweet Sent: #{text}"
  end
  
end
