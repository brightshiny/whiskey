require 'rmagick'

class Gobbler::ImageEater
  
    attr_reader :link
    
    def initialize(source,reference)
      reference = "%012d" % reference
      @source = source
      @dest = "/logos/" + reference.scan(/\d\d/).slice(0,5).join("/") +"/"
      @destfile = reference + ".jpg"
      @link = nil
    end
    
    def eat_logo
      puts "Getting from: #{@source}"
      puts "Putting in:   #{IMAGE_FILE_PATH}#{@dest}#{@destfile}"
      # get source
      # convert to jpg
      # save jpg
      # set link
      puts "Link:  " + IMAGE_WEB_PATH + @dest + @destfile 
    end
end