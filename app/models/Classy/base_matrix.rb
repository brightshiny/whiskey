require 'linalg'

module Classy
  # subclasses should implement get_a, get_q, and get_row
  class BaseMatrix
    
    def initialize()
      @matrix = MatrixInternals.new
    end
    
    def add_to_a(items)
      if items.kind_of? Enumerable
        items.each {|i| @matrix.add_to_a(i) }
      else
        @matrix.add_to_a(items)
      end
    end
    
    def get_term_index(term, create_new=false)
      return @matrix.get_term_index(term, create_new)
    end

  end
end
