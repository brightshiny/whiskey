module Classy
  class Spinner
    @@chars = %w{ | / - \\ }
    
    def initialize()
      @count = 0
      print ' '
    end
    
    def spin
      print "\b" + @@chars[(@count%4)]
      STDOUT.flush
      @count = @count + 1
    end
  end
end