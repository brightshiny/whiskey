#require 'hpricot'
require 'RMagick'

class Gobbler::ImageEater
  
    attr_reader :link
    
    def initialize(source,reference)
      reference = "%06d" % reference
      @source = source
      @destfile = reference + ".gif"
      @link = nil
    end
    
    def eat_logo
      FileUtils.makedirs(FEED_IMAGES_CACHE_DIR) #not doing 00 thing...
      image = nil
      begin
        doc = open("http://#{@source}")
        doc.each_line do |x|
          if x.match(/\<link.*?rel=\"(shortcut icon|icon)\"/)
            urlToTry = x.match(/href\s*="*(.*?)"*\s+/)[1]
            if urlToTry.match(/\.ico$/)
              image = Magick::Image.from_blob(open(urlToTry).read) { self.format = "ico" }[0]
            else
              image = Magick::Image.from_blob(open(urlToTry).read)
            end
            if image.x_resolution >= 50.0 || image.y_resolution >= 50.0
              image = nil
            end
           break
          end
        end
      rescue
      end
      if image.nil?
        begin
    #      image = Magick::ImageList.new("http://#{@source}/favicon.png")
          image = Magick::Image.from_blob(open("http://#{@source}/favicon.png").read)

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