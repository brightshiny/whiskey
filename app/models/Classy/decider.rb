require 'linalg'

module Classy
  class Decider
    @@K_MULTIPLIER = 2.4
    attr_reader :matrix
    
    def initialize(opts={})
      @matrix = TfIdfMatrix.new(opts)
    end
    
    def memes(opts={})
      q = opts[:q]
      a = opts[:a]
      verbose = opts[:verbose] || false
      spinner = verbose ? nil : Spinner.new
      user_id = opts[:user].id if opts[:user]
      
      if !q || !a
        puts "Hey! Missing important args in decider.memes_from_a. Goodbye."
        return
      end
      
      n = a.kind_of?(Enumerable) ? a.size : 1
      if opts[:k]
        k = opts[:k]
      else
        k = @@K_MULTIPLIER*Math.sqrt(n).ceil
      end
      
      run = Run.create({ :k => k, :n => n,
        :maximum_matches_per_query_vector => opts[:maximum_matches_per_query_vector], 
        :minimum_cosine_similarity => opts[:minimum_cosine_similarity],
        :skip_single_terms => opts[:skip_single_terms],
        :user_id => user_id})
      
      puts "\n==> Run Details:\n#{run.to_s}\n"
      
      run.started_at = Time.now
      run.save
      
      @matrix.add_to_a(a)
      run.distinct_term_count = @matrix.max_term_index
      run.save
      
      # magic in-memory data structure for meme processing
      buckets = []
      cosine_similarities = {}
      
      puts " " if !verbose # spinner needs space to grow
      
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
            cosine_similarities[doc.id] = {} unless cosine_similarities.has_key?(doc.id)
            cosine_similarities[doc.id][pdoc.id] = pdoc.score

            # add items to buckets if the buckets already exist
            still_searching = true
            for bucket in buckets 
              if bucket.keys.include?(pdoc.id) || bucket.keys.include?(doc.id)
                bucket[pdoc.id] = true
                bucket[doc.id] = true
                still_searching = false
              end
            end
            
            # otherwise make a new bucket
            if still_searching == true
              bucket = {}
              bucket[pdoc.id] = true
              bucket[doc.id] = true
              buckets.push(bucket)
              still_searching = false
            end
            
            total_score += pdoc.score
          end
        }
        puts "\tTotal Score: #{total_score} (#{total_score.to_f / predicted_docs.size.to_f} avg)" if verbose
      }      
      
      # puts
      # buckets.each { |bucket|
      #   puts "#{bucket.keys.join(", ")}"
      # }
      
      UberMeme.make_memes(:run => run, :buckets => buckets, :cosine_similarities => cosine_similarities)
      
      # umras = UberMemeRunAssociation.find(:all, :conditions => ["run_id = ?", run.id])
      # run.meme_strength_average = umras.map{ |umra| umra.strength }.sum / umras.size
      # total_sq_deviation = umras.map{ |umra| (run.meme_strength_average - umra.strength)**2 }.sum
      # run.meme_strength_standard_deviation = (Math.sqrt(total_sq_deviation / umras.size)).to_f
      # 
      # umras.each{ |umra| 
      #   umra.strength_z_score = umra.strength / run.meme_strength_standard_deviation
      #   umra.save
      # }
      
      puts "Making UMRAs..."
      run_data = {}
      uber_meme_run_ids = UberMemeItem.find_by_sql(["select uber_meme_id, run_id, sum(total_cosine_similarity) as strength from uber_meme_items where run_id = ? group by uber_meme_id, run_id", run.id])
      uber_meme_run_ids.each { |umi|
        if run_data[umi.run_id].nil?
          run_data[umi.run_id] = { :total_strength => 0, :number_of_uber_memes => 0, :strengths => [], :standard_deviation => 0 }
        end
        run_data[umi.run_id][:total_strength] += umi.strength.to_f
        run_data[umi.run_id][:number_of_uber_memes] += 1
        run_data[umi.run_id][:strengths].push({ :uber_meme_id => umi.uber_meme_id, :strength => umi.strength.to_f })
      }
      run_data.keys.each { |run_id|
        data = run_data[run_id]
        average_meme_strength = data[:total_strength] / data[:number_of_uber_memes]
        total_deviation = data[:strengths].map{ |s| (average_meme_strength - s[:strength])**2 }.sum
        run_data[run_id][:standard_deviation] = (Math.sqrt(total_deviation / data[:number_of_uber_memes])).to_f
      }
      uber_meme_run_ids.each { |umi|       
        UberMemeRunAssociation.create({ :uber_meme_id => umi.uber_meme_id, :run_id => umi.run_id, :strength => umi.strength.to_f, :strength_z_score => (umi.strength.to_f / run_data[umi.run_id][:standard_deviation]) }) 
      }
      puts "... done making UMRAs"
      
      run.ended_at = Time.now
      run.save
      return run
    end
    
    def process_q(docs, required_cos_sim=0.97, required_k=2, num_best_matches_to_return=2,skip_single_terms=false)
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

      # TODO: Return a hash w/doc id instead of hitting the db and load the actual item in another method later
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
