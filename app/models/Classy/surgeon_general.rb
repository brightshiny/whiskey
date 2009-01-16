module Classy
  class SurgeonGeneral 
    
    def self.assuage_keith
      feed = Feed.find_by_title('NYT > World')
      docs = Item.find(:all, :conditions => ["feed_id = ?", feed.id], :limit => 100, :order => "id desc")
      decider = Classy::Decider.new
      decider.add_to_a(docs)
      
      docs = [Item.find(56035)]
      
      for k in 2 .. 15 do
        docs.each do |doc|
          puts ">> k=#{k} #{doc.title}"
          predicted_docs = decider.enhanced_process_q([doc], 0.6, k, 10)
        end
      end
    end
    
    
    def self.assess_decider  
      
      overall_start_time = Time.now
      
      # Grab a user
      u = User.find(3)
      
      # Pick some dates that the user has read data
      #   - First date for "training"
      #   - Second date for making predictions
      date_containing_items_consumed_data = Date.parse('2008-12-23')
      date_to_make_predictions_about = Date.parse('2008-12-24')
      
      # Get the items the user actually read on the two dates of interest
      consumed_docs  = u.items_read_on(date_containing_items_consumed_data) + u.items_clicked_on(date_containing_items_consumed_data)
      puts "Found #{consumed_docs.size} consumed items on #{date_containing_items_consumed_data}"
      total_actually_consumed_docs = (u.items_read_on(date_to_make_predictions_about) + u.items_clicked_on(date_to_make_predictions_about)).uniq
      
      # Get the pool of documents the user had to pick from to make predictions
      documents_to_make_predictions_about = Item.find(:all, 
                                                      :conditions => ["date(published_at) = date(?)", date_to_make_predictions_about],
      :limit => 100
      )
      puts "Found #{documents_to_make_predictions_about.size} new documents to make predictions about on #{date_to_make_predictions_about}"
      
      # Do some batching 
      #   - Actually runs in under 10 hours
      #   - Maybe for eventual parallelism?
      total_predicted = 0 
      total_predicted_and_read = 0
      total_predicted_and_not_read = 0
      total_not_predicted_and_read = 0 
      total_documents_in_set = 0
      total_documents_actually_consumed = 0 
      sum_of_batch_times = 0
      batch_size = 20
      batch = 1
      while documents_to_make_predictions_about.size > 0
        
        start_time = Time.now
        
        # Break out this batch's documents
        documents_to_make_predictions_about_this_batch = documents_to_make_predictions_about.shift(batch_size)
        total_documents_in_set += documents_to_make_predictions_about_this_batch.size
        puts "Processing batch ##{batch} (items #{(batch-1)*batch_size+1} - #{batch*batch_size})"
        
        # Do decider work
        decider = Classy::Decider.new
        decider.add_to_a(documents_to_make_predictions_about_this_batch)      
        # enhanced_process_q(docs, required_cos_sim=0.97, required_k=2, num_best_matches_to_return=2)
        predicted_docs = decider.enhanced_process_q(consumed_docs, 0.999, Math.sqrt(consumed_docs.size / 2.0).floor, 2)
        
        if ! predicted_docs.empty? # There's a bug somewhere that can crash process_q and return an empty array 
          total_predicted += predicted_docs.size
          puts "\tDocuments in batch:\t\t#{documents_to_make_predictions_about_this_batch.size}"
          
          # For the sake of analysis, we're not comparing all the actually consumed items at once
          #   just those that are available in this particular batch of items
          actually_consumed_docs = total_actually_consumed_docs.reject{ |d| (! documents_to_make_predictions_about_this_batch.map{ |p| p.id }.include?(d.id)) }
          total_documents_actually_consumed += actually_consumed_docs.size
          puts "\tActual consumed documents:\t#{actually_consumed_docs.size}"
          puts "\tPredicted consumed documents:\t#{predicted_docs.size}"
          
          # Do bin math...
          actual_item_ids = actually_consumed_docs.map{ |i| i.id }
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
          
          total_predicted_and_read     += predicted_and_read
          total_predicted_and_not_read += predicted_and_not_read
          total_not_predicted_and_read += not_predicted_and_read
          
          puts "\tPredicted and consumed:\t\t#{predicted_and_read}"
          puts "\tPredicted and not consumed:\t#{predicted_and_not_read}"
          puts "\tNot predicted and consumed:\t#{not_predicted_and_read}"
        end 
        
        end_time = Time.now  
        batch_time = end_time - start_time
        puts "\t#{batch_time} seconds"
        sum_of_batch_times += batch_time
        batch += 1
        
        puts 
      end
      
      overall_end_time = Time.now
      
      puts "**********"
      puts "Total documents in set:\t\t\t#{total_documents_in_set}"
      puts "Total predicted:\t\t\t#{total_predicted}\t#{100 - 100 * total_predicted.to_f / total_documents_in_set.to_f}% corpus shrinkage"
      puts "Total actually consumed:\t\t#{total_documents_actually_consumed}"
      puts "Total predicted and consumed:\t\t#{total_predicted_and_read}"
      puts "Total predicted and not consumed:\t#{total_predicted_and_not_read}"
      puts "Total not predicted and consumed:\t#{total_not_predicted_and_read}\t#{100 * total_not_predicted_and_read.to_f / total_documents_actually_consumed.to_f}% missed completely"
      puts "#{overall_end_time - overall_start_time} seconds (overall)"
      puts "#{sum_of_batch_times.to_f / batch.to_f} seconds (per batch)"
      puts "**********"
      
      puts 
      
    end
    
    def self.assess_k  
      # feed_id = 280 # NYT: US
      feed_id = 25 # boingboing
      # feed_id = 277 # kotaku
      feed = Feed.find(feed_id)
      consumed_docs = Item.find(:all, 
        :conditions => ["feed_id = ?", feed.id], 
        :include => [ { :item_words, :word } ], 
        :order => "published_at desc",
        :limit => 200
      )
      documents_to_make_predictions_about = consumed_docs.clone

      decider = Classy::Decider.new
      decider.add_to_a(documents_to_make_predictions_about)
      
      puts "Analyzing #{consumed_docs.size} documents from #{feed.title}"
            
      2.upto(15) do |k| 
        
        File::open("#{RAILS_ROOT}/log/assess_k/f#{feed.id}_k#{k}_i#{documents_to_make_predictions_about.size}.log", "w") { |f| 
        
          start_time = Time.now
        
          f.puts 
          puts "K: #{k} | Items: #{documents_to_make_predictions_about.size}"
          f.puts "Processing #{documents_to_make_predictions_about.size} items (k = #{k})"
          
          consumed_docs.each_with_index { |doc, i| 
            STDOUT.print "."
            STDOUT.flush
            s = "\n\t#{doc.title}\n"
            predicted_docs = decider.enhanced_process_q([doc], 0.1, k, 10)
            predicted_docs.each { |pdoc|
              s += "\t\t%1.5f - %s\n" % [pdoc.score, pdoc.title]
            }
            f.puts s
          }
          
          end_time = Time.now  
          batch_time = end_time - start_time
          f.puts
          f.puts "#{batch_time} seconds"
          STDOUT.print " %5.3f sec\n" % batch_time
          puts
        }
        
      end
            
    end
    
  end
end
