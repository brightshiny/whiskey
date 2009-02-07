require 'linalg'

module Classy
  class MatrixInternals
    attr_reader :max_term_index, :max_doc_index, :doc_term_count_cache, :idf_cache, :doc_index_hash, :skip_single_terms
    
    def initialize(opts={})
      # columns = array of term count arrays
      @columns = Array.new
      @max_term_index = -1
      @max_doc_index = -1
      @term_index_hash = Hash.new
      @doc_index_hash = Hash.new
      @doc_term_count_cache = Hash.new
      @idf_cache = nil
      @dirty = false
      @skip_single_terms = opts[:skip_single_terms]
    end
    
    # add another doc to a
    def add_to_a(doc)
      @dirty = true
      doc_idx = get_doc_index(doc.id)
      @columns[doc_idx], @doc_term_count_cache[doc_idx] = doc_column(doc)
    end
    
    # returns a array (doc column) with term counts in positions consistent for this instance
    # create_new=true will add new terms to the known index
    def doc_column(doc, create_new=true)
      col = Array.new(@max_term_index+1, 0.0)
      doc_term_count = 0.0
      terms_skipped_count = 0
      total_terms_count = 0
      doc.item_words.each do |iw|
        count = iw.count.to_f
        total_terms_count += 1
        if count <= 1 && @skip_single_terms
          terms_skipped_count += 1
          next
        end
        word = iw.word.word
        term_idx = get_term_index(word,create_new)
        if term_idx != :term_dne
          col[term_idx] = count
          doc_term_count += count
        end
      end
      
      if @skip_single_terms && total_terms_count > 0
        ratio_skipped = terms_skipped_count.to_f / total_terms_count.to_f
        if ratio_skipped > 0.33
          puts "Warning: skipped #{sprintf("%0.2f", ratio_skipped*100.0)}% of the terms in document #{doc.id}.  Maybe you should disable skip_single_terms."
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
    
    def get_term_index(term, create_new=false)
      if @term_index_hash.has_key?(term)
        return @term_index_hash.fetch(term)
      elsif create_new
        return @term_index_hash[term] = @max_term_index += 1
      else
        return :term_dne
      end
    end
    
    def get_a
      clean
      Linalg::DMatrix.columns(@columns)
    end
    
  end
end
