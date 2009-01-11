module Classy
  class SurgeonGeneral 
    
    def self.assess_decider  
      
      u = User.find(3)
      
      date_containing_items_consumed_data = Date.parse('2008-12-23')
      date_to_make_predictions_about = Date.parse('2008-12-24')
      
      consumed_docs  = u.items_read_on(date_containing_items_consumed_data)
      puts "Found #{consumed_docs.size} consumed items (#{date_containing_items_consumed_data})"
      
      documents_to_make_prediction_from = Item.find(:all, 
        :conditions => ["date(published_at) = date(?)", date_to_make_predictions_about]
      )
      puts "Found #{documents_to_make_prediction_from.size} new documents to make predictions about (#{date_to_make_predictions_about})"
            
      total_actually_consumed_docs = u.items_read_on(date_to_make_predictions_about)
      
      batch_size = 100
      batch = 1
      while documents_to_make_prediction_from.size > 0
        
        decider = Classy::Decider.new
        
        start_time = Time.now
        documents_to_make_prediction_from_this_batch = documents_to_make_prediction_from.shift(batch_size)
        
        puts "Processing batch ##{batch} (items #{(batch-1)*batch_size+1} - #{batch*batch_size})"
        actually_consumed_docs = total_actually_consumed_docs.reject{ |d| (! documents_to_make_prediction_from_this_batch.map{ |p| p.id }.include?(d.id)) }
        puts "\tActually consumed documents:\t#{actually_consumed_docs.size}"

        decider.add_to_a(documents_to_make_prediction_from_this_batch)      
      
        predicted_docs = decider.process_q(consumed_docs)

        puts "\tDocuments in batch:\t\t#{documents_to_make_prediction_from_this_batch.size}"
        puts "\tSuggested documents:\t\t#{predicted_docs.size}"

        actual_item_ids = actually_consumed_docs.map{ |i| i.id }

        suggested_and_read = 0
        suggested_and_not_read = 0
        predicted_and_read = 0
        predicted_and_not_read = 0
        predicted_docs.each do |predicted_item|
          if actual_item_ids.include?(predicted_item.id)
            predicted_and_read += 1
          else
            predicted_and_not_read += 1
          end
        end
        not_predicted_and_read = actual_item_ids.size - predicted_and_read

        puts "\tSuggested and consumed:\t\t#{predicted_and_read}"
        puts "\tSuggested and not consumed:\t#{predicted_and_not_read}"
        puts "\tNot suggested and consumed:\t#{not_predicted_and_read}"
        
        puts "\tTime: #{end_time - start_time} seconds"
        batch += 1
        
        puts
        end_time = Time.now   
      end
      
    end
    
  end
end

