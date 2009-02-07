require 'linalg'

module Classy
  class Decider
    attr_reader :matrix
    
    def initialize
      super
      @matrix = TfIdfMatrix.new()
    end
    
    def process_q(docs, required_cos_sim=0.97, required_k=2, num_best_matches_to_return=2,skip_single_terms=false)
      #puts @matrix.get_a
      a = @matrix.get_a
      
      u, s, vt = a.singular_value_decomposition
      vt = vt.transpose
      
      cols_for_u2 = []
      cols_for_v2 = []
      eigenvectors = []
      k = required_k
      k.times do |n|
        cols_for_u2.push(u.column(n))
        cols_for_v2.push(vt.column(n))
        eigenvectors.push(s.column(n).to_a.flatten[0,k])
      end
      u2 = Linalg::DMatrix.join_columns(cols_for_u2)
      v2 = Linalg::DMatrix.join_columns(cols_for_v2)
      eig2 = Linalg::DMatrix.columns(eigenvectors)
      
      matched_documents = []
      docs.each do |doc|
        all_matched_documents = []
        q = @matrix.get_q(doc)
        q_embed = q * u2 * eig2.inverse
        doc_idx = 0
        v2.rows.each do |x|
          cos_sim = (q_embed.transpose.dot(x.transpose)) / (x.norm * q_embed.norm)
          if cos_sim >= required_cos_sim
            doc_id = @matrix.doc_idx_to_id(doc_idx)
            doc = Item.find(doc_id) if !doc_id.nil?
            title = doc.nil? ? "None?" : doc.title
            all_matched_documents.push({ :id => doc.id, :title => doc.title, :score => cos_sim })
          end
          doc_idx += 1
        end
        all_matched_documents.sort_by{ |d| d[:score] }.reverse[0..(num_best_matches_to_return-1)].each{ |d| matched_documents.push(d) }
      end
      documents = Item.find(:all, :conditions => ["id in (?)", matched_documents.map{ |d| d[:id] }])
      documents.each{ |d|
        d.score = matched_documents.select{ |md| md[:id] == d.id }.first[:score]
      }
      documents = documents.sort_by{ |d| d.score }.reverse
      return documents
      # rescue
      #   puts "Error in matching Qs"
      #   return []
      # end
    end    
  end
end
