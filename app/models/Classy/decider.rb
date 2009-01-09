require 'linalg'

module Classy
  class Decider
    
    def self.decide
      d = Classy::Decider.new
      d.term_doc_matrix()
    end
    
    def term_doc_matrix
      
      docs = get_docs(User.find(3))
      mb = MatrixBuilder.new()
      docs.each do |doc|
        mb.add(doc)
      end
      mb.tf_idf_matrix
      
    end
    
    def get_docs(user)
      return if user.nil?
      read_docs(user)
    end
    
    def read_docs(user,count=10)
      user.recently_read_items(count)
    end
  end
  
  class MatrixBuilder
    def initialize()
      super
      # columns = array of term count arrays
      @columns = Array.new
      @next_term_index = -1
      @next_doc_index = -1
      @term_index_hash = Hash.new
      @doc_index_hash = Hash.new
      @dirty = false
    end
    
    def add(doc)
      return unless !doc.nil?
      
      @dirty = true
      doc_idx = get_doc_index(doc.id)
      
      @columns[doc_idx] = Array.new
      doc.item_words.each do |iw|
        word = iw.word.word
        term_idx = get_term_index(word)
        @columns[doc_idx][term_idx] = iw.count
      end
    end
    
    # make @columns[][] a rectangle and zero out nils
    def clean
      if @dirty
        for doc_idx in 0 .. @columns.size-1
          for term_idx in 0 .. @next_term_index
            @columns[doc_idx][term_idx] = 0 unless !@columns[doc_idx][term_idx].nil?
          end
        end
        @dirty = false
      end
    end
    
    def term_count_matrix
      clean
      Linalg::DMatrix.columns(@columns)
    end
    
    def tf_idf_matrix
      clean
      # slicing time
      tf_idf_columns = Array.new
      for doc_idx in 0 .. @columns.size-1
        tf_idf_columns[doc_idx] = Array.new
        for term_idx in 0 .. @next_term_index
          word = @term_index_hash.index(term_idx)
          word_count = @columns[doc_idx][term_idx]
          doc_word_count = 0
          @columns[doc_idx].inject{|doc_word_count,n| doc_word_count + n}
          tf = word_count.to_f / doc_word_count.to_f
          idf = Math.log(@next_doc_index.to_f / number_of_docs_with_term(term_idx))
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
        return @doc_index_hash[doc_id] = @next_doc_index += 1
      end
    end
    
    def get_term_index(term)
      if @term_index_hash.has_key?(term)
        return @term_index_hash.fetch(term)
      else
        return @term_index_hash[term] = @next_term_index += 1
      end
    end
  end
  
end
