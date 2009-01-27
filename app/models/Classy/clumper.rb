module Classy
  class Clumper
    
    def self.make_clumps 
      
      user = User.find(5)
      consumed_docs = user.recent_documents_from_feeds(100)

      documents_to_make_predictions_about = consumed_docs.clone

      decider = Classy::Decider.new
      decider.add_to_a(documents_to_make_predictions_about)
      
      puts "Analyzing #{consumed_docs.size} documents from #{user.login}"      
                
      start_time = Time.now
    
      puts         
      k = 25    
      puts "K: #{k} | Items: #{documents_to_make_predictions_about.size}"
      puts "Processing #{documents_to_make_predictions_about.size} items (k = #{k})"
      
      clumps = []
      consumed_docs.each_with_index { |doc, i| 
        s = "\n\t#{doc.title}\n"    
        predicted_docs = decider.enhanced_process_q([doc], 0.80, k, 100)
        total_score = 0
        predicted_docs.each { |pdoc|
          s += "\t\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]
          total_score += pdoc.score
        }
        if total_score > 1.1
          puts s
          puts "\t\tTotal Score: #{total_score}"
          clumps.push({ :id => doc.id, :predicted_docs => predicted_docs, :total_score => total_score })
        end
      }
      
      puts
      # find the longest chain of predicted docs
      clumps = clumps.sort{ |a,b| b[:total_score] <=> a[:total_score] }
      clumps.each { |c1| 
        clumps.each { |c2|
          # eliminate all other docs w/predicted docs contained by the previous set
          # add in the extras
          if c1[:id] != c2[:id]
            if ((c2[:predicted_docs] - c1[:predicted_docs]).size.to_f / c2[:predicted_docs].size.to_f) < 0.20
              # puts "#{c1[:id]} | #{c2[:id]} (very similar)"
              c1[:predicted_docs] += c2[:predicted_docs]
              c1[:predicted_docs].uniq!
              clumps.delete(c2)
            elsif c2[:predicted_docs].map{ |d| d.id }.include?(c1[:id]) 
              # puts "#{c1[:id]} | #{c2[:id]} (included)"
              c1[:predicted_docs] += c2[:predicted_docs]
              c1[:predicted_docs].uniq!
              clumps.delete(c2)
            end
          end
        }
        # rince and repeat    
      }
      
      puts
      # sort 'em all up one more time
      clumps.each { |c| 
        if c[:predicted_docs].size > 3
          local_k = Math.sqrt(c[:predicted_docs].size).floor
          if local_k >= 2
            item = Item.find(c[:id])
            micro_decider = Classy::Decider.new
            micro_decider.add_to_a(c[:predicted_docs])
            ordered_docs = micro_decider.enhanced_process_q([item], 0.80, local_k, 100)
            if ordered_docs.size > 2
              puts "#{item.title} (#{item.id})"
              ordered_docs.each { |d| 
                puts "\t%1.5f - %s (%s)\n" % [d.score, d.title, d.id]
              }
            end
          end
        end
      }
      
      end_time = Time.now  
      batch_time = end_time - start_time
      puts
      STDOUT.print " %5.3f seconds\n" % batch_time
      puts
      
    end # make_clumps
    
    def self.riverdance
      user = User.find(5)
      consumed_docs = user.recent_documents_from_feeds(200)
      decider = Classy::Decider.new
      decider.add_to_a(consumed_docs)
      k = 30
      clumps = []
      consumed_docs.each_with_index { |doc, i| 
        s = "\n#{doc.title}\n"    
        predicted_docs = decider.enhanced_process_q([doc], 0.75, k, 105)
        total_score = 0
        predicted_docs.each { |pdoc|
          s += "\t%1.5f - %s (%s)\n" % [pdoc.score, pdoc.title, pdoc.id]
          total_score += pdoc.score
        }
        if total_score > 1.1
          puts s
          puts "\tTotal Score: #{total_score}"
          clumps.push({ :id => doc.id, :predicted_docs => predicted_docs, :total_score => total_score })
        end
      }
      ids_to_keep = []
      ids_to_ignore = []
      clumps = clumps.sort{ |a,b| b[:total_score] <=> a[:total_score] }
      clumps.each { |c1| 
        c1_predicted_item_ids = c1[:predicted_docs].map{ |d| d.id }
        clumps.each { |c2|
          if c1[:id] != c2[:id]
            puts "c1: #{c1[:id]} | c2: #{c2[:id]}"
            if c1_predicted_item_ids.include?(c2[:id]) || ((c2[:predicted_docs] - c1[:predicted_docs]).size.to_f / c2[:predicted_docs].size.to_f) < 0.50 || c2[:predicted_docs].map{ |x| x.id }.include?(c1[:id])
              puts "\tc1's predicted docs include c2"
              c1[:predicted_docs] += c2[:predicted_docs]
              c1[:predicted_docs].uniq!
              ids_to_keep.push(c1[:id])
              if ! ids_to_keep.include?(c2[:id])
                ids_to_ignore.push(c2[:id])
              end
            end
          end
        }        
      }     
      puts
      puts "*************************************************"
      puts "*************************************************"
      puts "*************************************************"
      puts
      
      clumps.each { |c| 
        if ! ids_to_ignore.include?(c[:id])
          if c[:predicted_docs].size > 3
            puts "#{c[:id]}"
            c[:predicted_docs].each { |d| 
              puts "\t#{d.id}) #{d.title}"
            }
            puts
          end
        end
      }
      
      puts
      puts "*************************************************"
      puts "*************************************************"
      puts "*************************************************"
      puts
      
      # sort 'em all up one more time
      # clumps.each { |c| 
      #   if ! ids_to_ignore.include?(c[:id])
      #     if c[:predicted_docs].size > 3
      #       local_k = (c[:predicted_docs].size/2.0).floor
      #       if local_k >= 2
      #         item = Item.find(c[:id])
      #         micro_decider = Classy::Decider.new
      #         micro_decider.add_to_a(c[:predicted_docs])
      #         ordered_docs = micro_decider.enhanced_process_q([item], 0.80, local_k, 100)
      #         if ordered_docs.size >= 2
      #           puts "#{item.title} (#{item.id})"
      #           ordered_docs.each { |d| 
      #             puts "\t%1.5f - %s (%s)\n" % [d.score, d.title, d.id]
      #           }
      #         end
      #       end
      #     end
      #   end
      # }
      
    end
    
  end
end