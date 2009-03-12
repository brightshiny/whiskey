#require 'hpricot'
require 'RMagick'


class Gobbler::ImageEater
  
    attr_reader :link
    
    def initialize(source,reference)
      reference = "%06d" % reference
      @source = source
      @destfile = reference + ".jpg"
      @link = nil
    end
    
    def eat_logo
      FileUtils.makedirs(FEED_IMAGES_CACHE_DIR) #not doing 00 thing...
      image = nil
      begin
        doc = open("http://#{@source}")
        doc.each_line do |x|
          if x.match(/link.*rel\s*="*shortcut*\s*icon"*\s+/)
            urlToTry = x.match(/href\s*="*(.*?)"*\s+/)[1]
            image = Magick::Image.from_blob(open(urlToTry).read) { self.format = "ico" }[0]
            break
          end
        end
      rescue
      end
      if image.nil?
        begin
          image = Magick::ImageList.new("http://#{@source}/favicon.png")
        rescue
        end
        if image.nil?
          begin
            image = Magick::Image.from_blob(open("http://#{@source}/favicon.ico").read) { self.format = "ico" }[0]
          rescue
          end
        end
      end
      
      if !image.nil?
        image.write("#{FEED_IMAGES_CACHE_DIR}/#{@destfile}")
        @link = "#{FEED_IMAGES_SRC}/#{@destfile}"
      end
    end
end