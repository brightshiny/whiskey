class Series < ActiveRecord::BaseWithoutTable
  
  def self.go
    
    # defaults
    number_of_documents_for_a = 200
    k=30
    minimum_cosine_similarity = 0.9
    maximum_matches_per_query_vector = 50
    skip_single_terms = false
    
    # get the user
    user = User.find(5) # user named "clone"
    
    time = user.recent_documents_from_feeds(1).first.published_at + 10.seconds
    1.upto(168) do |n|    
      end_time = time
      start_time = end_time - 12.hours
      
      consumed_docs = user.documents_from_feeds_by_date_range(start_time, end_time) 
      
      k = (Math.sqrt(consumed_docs.size).ceil * 2)
      
      puts
      puts "******************************************"
      puts "Consumed Docs: #{consumed_docs.size}"
      puts "Batch #{n}" 
      puts 
      puts "Starting run with the following settings: "
      run = Run.create({ :k => k, :n => consumed_docs.size, :maximum_matches_per_query_vector => maximum_matches_per_query_vector, :minimum_cosine_similarity => minimum_cosine_similarity, :skip_single_terms => skip_single_terms })
      puts run.to_s
      puts
      
      run.started_at = Time.now
      decider = Classy::Decider.new(:skip_single_terms => skip_single_terms)
      decider.matrix.add_to_a(consumed_docs)
      run.distinct_term_count = decider.matrix.max_term_index
      run.save
      
      # magic in-memory data structure for meme processing
      relationship_map = {}
    
      consumed_docs.each_with_index { |doc, i| 
        puts "\n#{doc.title}\n"    
        predicted_docs = decider.process_q([doc], run.minimum_cosine_similarity, run.k, run.maximum_matches_per_query_vector, run.skip_single_terms)
        total_score = 0
        predicted_docs.each { |pdoc|
          if doc.id == pdoc.id
            puts "\t(skipped) %1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]
          else
            puts "\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]
            ir = ItemRelationship.create({ :item_id => doc.id, :related_item_id => pdoc.id, :run_id => run.id, :cosine_similarity => pdoc.score }) 
            relationship_map[ir.item_id] = Array.new unless relationship_map.has_key?(ir.item_id)
            relationship_map[ir.item_id].push(ir)
            total_score += pdoc.score
          end
        }
        puts "\tTotal Score: #{total_score} (#{total_score.to_f / predicted_docs.size.to_f} avg)"
      }
      # generate memes!
      Meme.memes_from_item_relationship_map(run, relationship_map, true)
      run.ended_at = Time.now
      run.save  
      
      time = time - 1.hour
    end
    
  end
  
end
