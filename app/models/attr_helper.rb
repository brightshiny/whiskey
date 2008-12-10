class AttrHelper
  def self.get_first(obj, attrs)
    return nil if obj.nil? || attrs.nil?
    
    attrs.each do |attr|
      val = obj.send(attr)
      return val if !val.nil? && val.to_s.length > 0
    end
    return nil
  end
end