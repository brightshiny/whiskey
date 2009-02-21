require 'linalg'

module Classy
  class Decider
    attr_reader :matrix
    
    def initialize(opts={})
      @matrix = TfIdfMatrix.new(opts)
    end
    
    def memes(opts={})
      q = opts[:q]
      a = opts[:a]
      verbose = opts[:verbose] || false
      spinner = verbose ? nil : Spinner.new
      
      if !q || !a
        puts "Hey! Missing important args in decider.memes_from_a. Goodbye."
        return
      end
      
      n = a.kind_of?(Enumerable) ? a.size : 1
      run = Run.create({ :k => opts[:k], :n => n,
        :maximum_matches_per_query_vector => opts[:maximum_matches_per_query_vector], 
        :minimum_cosine_similarity => opts[:minimum_cosine_similarity],
        :skip_single_terms => opts[:skip_single_terms] })
      
      puts "\n==> Run Details:\n#{run.to_s}\n"

      run.started_at = Time.now
      run.save
      
      @matrix.add_to_a(a)
      run.distinct_term_count = @matrix.max_term_index
      run.save
      
      # magic in-memory data structure for meme processing
      relationship_map = {}
      
      # kmb: check for Enumerable in q
      q.each { |doc|
        
        if verbose
          puts "\n#{doc.title} (#{doc.id})\n"
        else
          spinner.spin
        end
        
        predicted_docs = process_q([doc], run.minimum_cosine_similarity, run.k, run.maximum_matches_per_query_vector, run.skip_single_terms)
        total_score = 0
        predicted_docs.each { |pdoc|
          if doc.id == pdoc.id
            puts "\t(skipped) %1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id] if verbose
          else
            puts "\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id] if verbose
            ir = ItemRelationship.create({ :item_id => doc.id, :related_item_id => pdoc.id, :run_id => run.id, :cosine_similarity => pdoc.score }) 
            relationship_map[ir.item_id] = Array.new unless relationship_map.has_key?(ir.item_id)
            relationship_map[ir.item_id].push(ir)
            total_score += pdoc.score
          end
        }
        puts "\tTotal Score: #{total_score} (#{total_score.to_f / predicted_docs.size.to_f} avg)" if verbose
      }
      
      # generate memes!
      Meme.memes_from_item_relationship_map(run, relationship_map, true)
      run.ended_at = Time.now
      run.save
      return run
    end
    
    def process_q(docs, required_cos_sim=0.97, required_k=2, num_best_matches_to_return=2,skip_single_terms=false)
      t1 = Time.now
      #puts @matrix.get_a
      
      u2, v2, eig2 = @matrix.process_svd(required_k)
      
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
      t2 = Time.now
      puts "Time: #{t2 - t1} seconds"
      return documents
      # rescue
      #   puts "Error in matching Qs"
      #   return []
      # end
    end    
  end
end
