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
      docs = User.find(3).recently_read_items(5)
      decider.add_to_a(docs)
      decider.process_q(docs)
      
    end
    
    def process_q(docs)
      #puts decider.matrix_builder.a_term_count
      a = @matrix_builder.a_tf_idf
      u, s, vt = a.singular_value_decomposition
      vt = vt.transpose
      
      u2 = Linalg::DMatrix.join_columns [u.column(0), u.column(1)]
      v2 = Linalg::DMatrix.join_columns [vt.column(0), vt.column(1)]
      eig2 = Linalg::DMatrix.columns [s.column(0).to_a.flatten[0,2], s.column(1).to_a.flatten[0,2]]
            
      # run through a bunch of Q
      docs.each do |doc|
        puts "Doc: [#{doc.title}] compares to:"
        q = @matrix_builder.get_q(doc)
        q_embed = q * u2 * eig2.inverse
        doc_idx = 0
        v2.rows.each do |x|
          cos_sim = (q_embed.transpose.dot(x.transpose)) / (x.norm * q_embed.norm)
          doc_id = @matrix_builder.doc_idx_to_id(doc_idx)
          doc = Item.find(doc_id) if !doc_id.nil?
          title = doc.nil? ? "None?" : doc.title
          printf "%10.5f %s\n", cos_sim, title
          doc_idx += 1
        end
      end
    end
    
    
    def add_to_a(items)
      items.each do |i|
        @matrix_builder.add_to_a(i)
      end
    end
    
  end
end
