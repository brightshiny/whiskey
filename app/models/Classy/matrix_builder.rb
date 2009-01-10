module Classy
  class MatrixBuilder
    attr_reader :max_term_index, :max_doc_index
    
    def initialize()
      super
      # columns = array of term count arrays
      @columns = Array.new
      @max_term_index = -1
      @max_doc_index = -1
      @term_index_hash = Hash.new
      @doc_index_hash = Hash.new
      @idf_cache = nil
      @dirty = false
    end
    
    def add_to_a(doc)
      @dirty = true
      doc_idx = get_doc_index(doc.id)
      @columns[doc_idx] = doc_column(doc)
    end
    
    # returns a array (doc column) with term counts in positions consistent for this instance
    # create_new=true will add new terms to the known index
    def doc_column(doc, create_new=true)
      col = Array.new(@max_term_index+1, 0.0)
      doc.item_words.each do |iw|
        word = iw.word.word
        term_idx = get_term_index(word,create_new)
        col[term_idx] = iw.count unless term_idx == :term_dne
      end
      return col
    end
    
    # make @columns[][] a rectangle and zero out nils
    def clean
      if @dirty
        @idf_cache = Array.new(@max_term_index+1)
        for term_idx in 0 .. @max_term_index
          docs_with_term_count = 0
          for doc_idx in 0 .. @columns.size-1
            if @columns[doc_idx][term_idx].nil?
              @columns[doc_idx][term_idx] = 0
            else
              docs_with_term_count += 1
            end
          end
          @idf_cache[term_idx] = Math.log(@columns.size.to_f/docs_with_term_count.to_f)
        end
        @dirty = false
      end
    end
    
    def get_q(item)
      col = doc_column(item, false)
      term_count = 0
      col.inject{|term_count,n| term_count + n}
      for term_idx in 0 .. @max_term_index
        tf = col[term_idx].to_f / term_count.to_f
        idf = @idf_cache[term_idx]
        col[term_idx] = tf*idf
      end
      
      return Linalg::DMatrix.rows([col])
    end
    
    def a_term_count
      clean
      Linalg::DMatrix.columns(@columns)
    end
    
    def a_tf_idf
      clean
      # slicing time
      tf_idf_columns = Array.new
      for doc_idx in 0 .. @columns.size-1
        tf_idf_columns[doc_idx] = Array.new
        for term_idx in 0 .. @max_term_index
          #word = @term_index_hash.index(term_idx)
          word_count = @columns[doc_idx][term_idx]
          doc_word_count = 0
          @columns[doc_idx].inject{|doc_word_count,n| doc_word_count + n}
          tf = word_count.to_f / doc_word_count.to_f
          idf = @idf_cache[term_idx]
          tf_idf_columns[doc_idx][term_idx] = tf*idf
        end
      end
      
      return Linalg::DMatrix.columns(tf_idf_columns)
    end
    
    def number_of_docs_with_term(term_idx)
      count = 0.0
      for doc_idx in 0 .. @columns.size-1
        count += 1.0 if @columns[doc_idx][term_idx] > 0
      end
      return count
    end
    
    def get_doc_index(doc_id)
      if @doc_index_hash.has_key?(doc_id)
        return @doc_index_hash.fetch(doc_id)
      else
        return @doc_index_hash[doc_id] = @max_doc_index += 1
      end
    end
    
    def doc_idx_to_id(idx)
      return @doc_index_hash.index(idx)
    end
    
    def get_term_index(term, create_new=true)
      if @term_index_hash.has_key?(term)
        return @term_index_hash.fetch(term)
      elsif create_new
        return @term_index_hash[term] = @max_term_index += 1
      else
        return :term_dne
      end
    end
  end
end