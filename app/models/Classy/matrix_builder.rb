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
      @doc_term_count_cache = Hash.new
      @idf_cache = nil
      @dirty = false
    end
    
    def add_to_a(doc)
      @dirty = true
      self.cached_a_tf_idf = nil
      doc_idx = get_doc_index(doc.id)
      @columns[doc_idx], @doc_term_count_cache[doc_idx] = doc_column(doc)
    end
    
    # returns a array (doc column) with term counts in positions consistent for this instance
    # create_new=true will add new terms to the known index
    def doc_column(doc, create_new=true)
      col = Array.new(@max_term_index+1, 0.0)
      doc_term_count = 0.0
      doc.item_words.each do |iw|
        word = iw.word.word
        term_idx = get_term_index(word,create_new)
        if term_idx != :term_dne
          count = iw.count.to_f
          col[term_idx] = count
          doc_term_count += count
        end
      end
      return [col, doc_term_count]
    end
    
    # make @columns[][] a rectangle and zero out nils
    def clean
      if @dirty
        @idf_cache = Array.new(@max_term_index+1)
        for term_idx in 0 .. @max_term_index
          docs_with_term_count = 0.0
          for doc_idx in 0 .. @columns.size-1
            if @columns[doc_idx][term_idx].nil?
              @columns[doc_idx][term_idx] = 0.0
            elsif @columns[doc_idx][term_idx] > 0
              docs_with_term_count += 1.0
            end
          end
          @idf_cache[term_idx] = Math.log(@columns.size.to_f/docs_with_term_count)
        end
        @dirty = false
      end
    end
    
    def term_count_row(term)
      term_idx = get_term_index(term, false)
      if term_idx == :term_dne
        return nil
      else
        return a_term_count.row(term_idx)
      end
    end
    
    def tf_idf_row(term)
      term_idx = get_term_index(term, false)
      if term_idx == :term_dne
        return nil
      else
        return a_tf_idf.row(term_idx)
      end
    end
    
    def q_term_count(item)
      col, doc_term_count = doc_column(item, false)
      return Linalg::DMatrix.rows([col])
    end
    
    def q_tf_idf(item)
      col, term_count = doc_column(item, false)
      for term_idx in 0 .. @max_term_index
        tf = term_count > 0.0 ? col[term_idx] / term_count : 0.0
        idf = @idf_cache[term_idx]
        col[term_idx] = tf*idf
      end
      
      return Linalg::DMatrix.rows([col])
    end
    
    def a_term_count
      clean
      Linalg::DMatrix.columns(@columns)
    end
    attr_accessor :cached_a_tf_idf
    def a_tf_idf(skip_single_terms=false)
      if self.cached_a_tf_idf.nil?
        clean
        # slicing time
        tf_idf_columns = Array.new
        for doc_idx in 0 .. @columns.size-1
          tf_idf_columns[doc_idx] = Array.new
          for term_idx in 0 .. @max_term_index
            #word = @term_index_hash.index(term_idx)
            term_count = @columns[doc_idx][term_idx]
            if skip_single_terms && term_count <= 1
              tf = idf = 0
            elsif
              doc_term_count = @doc_term_count_cache[doc_idx]
              tf = doc_term_count > 0.0 ? (term_count / doc_term_count) : 0.0
              idf = @idf_cache[term_idx]
            end
            tf_idf_columns[doc_idx][term_idx] = tf*idf
          end
        end
        self.cached_a_tf_idf = Linalg::DMatrix.columns(tf_idf_columns)
      end
      return self.cached_a_tf_idf
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
    
    def get_term_index(term, create_new=false)
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
