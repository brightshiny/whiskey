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
      return if !items
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
    
    attr_accessor :cached_u2v2eig2
    def process_svd(required_k)
      if self.cached_u2v2eig2.nil?
        a = self.get_a
        u, s, vt = a.singular_value_decomposition
        vt = vt.transpose
        cols_for_u2 = []
        cols_for_v2 = []
        eigenvectors = []
        k = required_k > vt.hsize ? vt.hsize : required_k
        k.times do |n|
          cols_for_u2.push(u.column(n))
          cols_for_v2.push(vt.column(n))
          eigenvectors.push(s.column(n).to_a.flatten[0,k])
        end
        u2 = Linalg::DMatrix.join_columns(cols_for_u2)
        v2 = Linalg::DMatrix.join_columns(cols_for_v2)
        eig2 = Linalg::DMatrix.columns(eigenvectors)
        # return [u2,v2,eig2]
        self.cached_u2v2eig2 = [u2,v2,eig2]
      end      
      return self.cached_u2v2eig2
    end
    
  end
end
