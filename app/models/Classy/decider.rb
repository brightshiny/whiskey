require 'linalg'

module Classy
  class Decider
    attr_reader :matrix_builder
    
    def initialize
      super
      @matrix_builder = MatrixBuilder.new()
    end
    
    def self.decide
      # make us a decider
      decider = Classy::Decider.new
      
      # define the corpus, add to A
      docs = User.find(1).recently_read_items(100)
      decider.add_to_a(docs)
      decider.process_q(docs)
      
    end
    
    def process_q(docs)
      #puts decider.matrix_builder.a_term_count
      a = @matrix_builder.a_tf_idf
      u, s, vt = a.singular_value_decomposition
      vt = vt.transpose
      
      cols_for_u2 = []
      cols_for_v2 = []
      eigenvectors = []
      k = Math.sqrt(docs.size).floor # dimensionality reduction
      k.times do |n|
        cols_for_u2.push(u.column(n))
        cols_for_v2.push(vt.column(n))
        eigenvectors.push(s.column(n).to_a.flatten[0,k])
      end
      u2 = Linalg::DMatrix.join_columns(cols_for_u2)
      v2 = Linalg::DMatrix.join_columns(cols_for_v2)
      eig2 = Linalg::DMatrix.columns(eigenvectors)
      
      # run through a bunch of Q
      matched_documents = []
      docs.each do |doc|
        # puts "Doc: [#{doc.title}] compares to:"
        q = @matrix_builder.q_tf_idf(doc)
        q_embed = q * u2 * eig2.inverse
        doc_idx = 0
        v2.rows.each do |x|
          cos_sim = (q_embed.transpose.dot(x.transpose)) / (x.norm * q_embed.norm)
          if cos_sim >= 0.95
            doc_id = @matrix_builder.doc_idx_to_id(doc_idx)
            doc = Item.find(doc_id) if !doc_id.nil?
            title = doc.nil? ? "None?" : doc.title
            # printf "%10.5f %s\n", cos_sim, title
            matched_documents.push({ :id => doc.id, :title => doc.title, :score => cos_sim })
          end
          doc_idx += 1
        end
        # matched_documents.sort_by{ |d| d[:score] }.reverse[0..2].each{ |d| printf "%10.5f (%d) %s \n", d[:score], d[:i
      end
      documents = Item.find(:all, :conditions => ["id in (?)", matched_documents.map{ |d| d[:id] }])
      return documents
    end
    
    def enhanced_process_q(docs)
      begin
        #puts decider.matrix_builder.a_term_count
        a = @matrix_builder.a_tf_idf
        u, s, vt = a.singular_value_decomposition
        vt = vt.transpose
      
        cols_for_u2 = []
        cols_for_v2 = []
        eigenvectors = []
        k = Math.sqrt(docs.size).floor # dimensionality reduction
        k.times do |n|
          cols_for_u2.push(u.column(n))
          cols_for_v2.push(vt.column(n))
          eigenvectors.push(s.column(n).to_a.flatten[0,k])
        end
        u2 = Linalg::DMatrix.join_columns(cols_for_u2)
        v2 = Linalg::DMatrix.join_columns(cols_for_v2)
        eig2 = Linalg::DMatrix.columns(eigenvectors)
      
        # run through a bunch of Q
        matched_documents = []
        docs.each do |doc|
            all_matched_documents = []
            # puts "Doc: [#{doc.title}] compares to:"
            q = @matrix_builder.q_tf_idf(doc)
            q_embed = q * u2 * eig2.inverse
            doc_idx = 0
            v2.rows.each do |x|
              cos_sim = (q_embed.transpose.dot(x.transpose)) / (x.norm * q_embed.norm)
              if cos_sim >= 0.98
                doc_id = @matrix_builder.doc_idx_to_id(doc_idx)
                doc = Item.find(doc_id) if !doc_id.nil?
                title = doc.nil? ? "None?" : doc.title
                # printf "%10.5f %s\n", cos_sim, title
                all_matched_documents.push({ :id => doc.id, :title => doc.title, :score => cos_sim })
              end
              doc_idx += 1
            end
            all_matched_documents.sort_by{ |d| d[:score] }.reverse[0..2].each{ |d| matched_documents.push(d) }
        end
        documents = Item.find(:all, :conditions => ["id in (?)", matched_documents.map{ |d| d[:id] }])
        return documents
      rescue
        puts "Error in matching Qs"
        return []
      end
    end
    
    
    def add_to_a(items)
      items.each do |i|
        @matrix_builder.add_to_a(i)
      end
    end
    
  end
end
