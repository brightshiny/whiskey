class MoveUberMemeRunsIntoAssn < ActiveRecord::Migration
  def self.up
    run_data = {}
    uber_meme_run_ids = UberMemeItem.find_by_sql("select uber_meme_id, run_id, sum(total_cosine_similarity) as strength from uber_meme_items group by uber_meme_id, run_id")
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
  end

  def self.down
    execute "truncate table #{UberMemeRunAssociation.table_name}"
  end
end
