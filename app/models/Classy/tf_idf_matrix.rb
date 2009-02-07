require 'linalg'

module Classy
  class TfIdfMatrix < BaseMatrix
    attr_accessor :cached_a_tf_idf
    
    def get_row(term)
      term_idx = get_term_index(term, false)
      if term_idx == :term_dne
        return nil
      else
        return get_a.row(term_idx)
      end
    end
    
    def get_q(item)
      col, term_count = @matrix.doc_column(item, false)
      for term_idx in 0 .. @matrix.max_term_index
        tf = term_count > 0.0 ? col[term_idx] / term_count : 0.0
        idf = @matrix.idf_cache[term_idx]
        col[term_idx] = tf*idf
      end
      
      return Linalg::DMatrix.rows([col])
    end
    
    def get_a()
      base_a = @matrix.get_a
      
      if self.cached_a_tf_idf.nil?
        # slicing time
        tf_idf_columns = Array.new
        for doc_idx in 0 .. base_a.hsize-1
          tf_idf_columns[doc_idx] = Array.new
          for term_idx in 0 .. base_a.vsize-1
            #word = @term_index_hash.index(term_idx)
            term_count = base_a[term_idx,doc_idx]
            doc_term_count = @matrix.doc_term_count_cache[doc_idx]
            tf = doc_term_count > 0.0 ? (term_count / doc_term_count) : 0.0
            idf = @matrix.idf_cache[term_idx]
            tf_idf_columns[doc_idx][term_idx] = tf*idf
          end
        end
        self.cached_a_tf_idf = Linalg::DMatrix.columns(tf_idf_columns)
      end
      return self.cached_a_tf_idf
    end
    
  end
end
