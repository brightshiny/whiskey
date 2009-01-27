class Run < ActiveRecord::Base
  has_many :item_relationships
  has_many :items, :through => :item_relationships
  
  def self.on_your_mark_get_set_go
    if ARGV.size != 0 && ARGV.size != 4
      puts "You must call 'on_your_marks_get_set_go' thusly: "
      puts "\nscript/runner Run.on_your_marks_get_set_go 1 2 3 4"
      puts "\nWhere:\n\t1 is the number of documents for a\n\t2 is k\n\t3 is minimum cosine similarity\n\t4 is maximum docs returned"
    else
      number_of_documents_for_a = ARGV[0].nil? ? 100 : ARGV[0].to_i
      k = ARGV[1].nil? ? 30 : ARGV[1].to_i
      minimum_cosine_similarity = ARGV[2].nil? ? 0.9 : ARGV[2].to_f
      maximum_matches_per_query_vector = ARGV[3].nil? ? 20 : ARGV[3].to_i
    
      puts "Starting run with the following settings: "
      puts "\tnumber_of_documents_for_a: #{number_of_documents_for_a}"
      puts "\tk: #{k}"
      puts "\tminimum_cosine_similarity: #{minimum_cosine_similarity}"
      puts "\tmaximum_matches_per_query_vector: #{maximum_matches_per_query_vector}"
      puts
    
      run = Run.create({ :k => k, :n => number_of_documents_for_a, :maximum_matches_per_query_vector => maximum_matches_per_query_vector, :minimum_cosine_similarity => minimum_cosine_similarity })
      
      user = User.find(5) # user named "clone"
      
      consumed_docs = user.recent_documents_from_feeds(number_of_documents_for_a)
      decider = Classy::Decider.new
      decider.add_to_a(consumed_docs)
      
      consumed_docs.each_with_index { |doc, i| 
        puts "\n#{doc.title}\n"    
        predicted_docs = decider.enhanced_process_q([doc], minimum_cosine_similarity, k, maximum_matches_per_query_vector)
        total_score = 0
        predicted_docs.each { |pdoc|
          puts "\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]          
          ir = ItemRelationship.create({ :item_id => doc.id, :related_item_id => pdoc.id, :run_id => run.id, :cosine_similarity => pdoc.score }) 
          total_score += pdoc.score
        }
        puts "\tTotal Score: #{total_score} (#{total_score.to_f / predicted_docs.size.to_f} avg)"
      }
    end
  end
  
end
