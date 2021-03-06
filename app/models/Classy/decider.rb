require 'linalg'

module Classy
  class Decider
    @@K_MULTIPLIER = 2.45
    attr_reader :matrix
    
    def initialize(opts={})
      @matrix = TfIdfMatrix.new(opts)
    end
    
    def memes(opts={})
      q = opts[:q]
      a = opts[:a]
      
      all_docs = q
       
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
        
        predicted_docs = process_q([doc], all_docs, run.minimum_cosine_similarity, run.k, run.maximum_matches_per_query_vector, run.skip_single_terms)
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
      
      UberMeme.make_memes(:run => run, :buckets => buckets, :cosine_similarities => cosine_similarities)
      
      puts "Making UMRAs..."
      run_data = {}
      # uber_meme_run_ids = UberMemeItem.find_by_sql(["select uber_meme_id, run_id, sum(total_cosine_similarity) as strength from uber_meme_items where run_id = ? group by uber_meme_id, run_id", run.id])
      uber_meme_run_ids = UberMemeItem.find_by_sql(["select uber_meme_id, run_id, sum(mean_strength_per_feed) as strength from (select umi.uber_meme_id, umi.item_id, umi.run_id, i.id, sum(umi.total_cosine_similarity), count(i.feed_id), sum(umi.total_cosine_similarity) / count(i.feed_id) as mean_strength_per_feed, i.feed_id from uber_meme_items umi join items i on i.id = umi.item_id where umi.run_id = ? group by i.feed_id) as A group by uber_meme_id order by uber_meme_id", run.id])
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
      umras = []
      uber_meme_run_ids.each { |umi|       
        umras.push(UberMemeRunAssociation.create({ :uber_meme_id => umi.uber_meme_id, :run_id => umi.run_id, :strength => umi.strength.to_f, :strength_z_score => (umi.strength.to_f / run_data[umi.run_id][:standard_deviation]) }))
      }
      puts "... done making UMRAs"
      
      run.ended_at = Time.now
      run.save
      
      begin
        strongest_meme = umras.sort{ |a,b| b.strength_z_score <=> a.strength_z_score }.first
        strong_enough = false
        if strongest_meme.strength_z_score > 3.4
          puts "Tweeting Strongest Meme (#{strongest_meme.strength_z_score}): #{strongest_meme.uber_meme.item.title}"
          TwitterClient.send_item(strongest_meme.uber_meme)
          strong_enough = true
        else
          puts "Not strong enough: #{strongest_meme.strength_z_score}"
        end  
        TwitterClient.send_private("R #{run.id} / M #{umras.size} / S #{(((strongest_meme.strength_z_score)*100).floor.to_f)/100.0} / T #{((((run.ended_at - run.started_at) / 60) * 100).floor.to_f)/100} min")
      rescue
       puts "Twitter stuff failed"
      end
      
      return run
    end
    
    def process_q(docs, all_docs, required_cos_sim=0.97, required_k=2, num_best_matches_to_return=2,skip_single_terms=false)
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
            doc2 = all_docs.select{ |d2| d2.id == doc_id }[0] # Item.find(doc_id) if !doc_id.nil?
            title = doc2.nil? ? "None?" : doc2.title
            all_matched_documents.push({ :id => doc2.id, :title => doc2.title, :score => cos_sim })
          end
          doc_idx += 1
        end
        all_matched_documents.sort_by{ |d| d[:score] }.reverse[0..(num_best_matches_to_return-1)].each{ |d| matched_documents.push(d) }
      end

      documents = []
      matched_documents.each { |d| 
        document = all_docs.select{ |d2| d2.id == d[:id] }[0]
        if ! document.nil? # is this right?
          document.score = d[:score]
          documents.push(document)
        end
      }
      documents = documents.sort_by{ |d| d.score }.reverse
      return documents
    end    
  end
end
