class AttrHelper
  def self.get_first(obj, attrs)
    return nil if obj.nil? || attrs.nil?
    
    val = nil
    attrs.each do |attr|
      val = obj.send(attr)
      break unless val.nil?
    end
    return val
  end
end