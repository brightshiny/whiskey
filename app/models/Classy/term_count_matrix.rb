require 'linalg'

module Classy
  class TermCountMatrix < BaseMatrix
    
    def get_row(term)
      term_idx = get_term_index(term, false)
      if term_idx == :term_dne
        return nil
      else
        return get_a.row(term_idx)
      end
    end
    
    def get_q(item)
      col, doc_term_count = @matrix.doc_column(item, false)
      return Linalg::DMatrix.rows([col])
    end
    
    def get_a
      return @matrix.get_a
    end
    
  end
end
