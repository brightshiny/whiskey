require 'linalg'

module Classy
  
  class BaseMatrix
    # subclasses should implement get_a, get_q, and get_row
    
    # usage:
    #
    #      @matrix = TfIdfMatrix.new({skip_single_terms => true})
    #      @matrix.add_to_a(docs)
    #      a = @matrix.get_a
    #      q = @matrix.get_q(doc)
    #      
    
    def initialize(opts={})
      @matrix = MatrixInternals.new(opts)
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
    
    def max_term_index
      return @matrix.max_term_index
    end
    
    def doc_idx_to_id(idx)
      return @matrix.doc_index_hash.index(idx)
    end
    
  end
end
