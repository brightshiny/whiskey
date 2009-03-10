class ImageSrc
  attr_accessor :src
  attr_accessor :item
  
  def initialize(src,item)
    @src = src
    @item = item
  end
  
  def local_location_dir(image)
    dirs = sprintf("%010d", image.id).scan(/../)
    dirs.pop
    return dirs.join('/')
  end
end