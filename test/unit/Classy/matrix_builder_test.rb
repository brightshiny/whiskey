require 'test_helper'
require 'linalg'

class MatrixBuilderTest < ActiveSupport::TestCase
  # Test based on data presented at: http://www.igvita.com/2007/01/15/svd-recommendation-system-in-ruby/
  # Bent from 5-star ratings into repeat-word-5-times doc data
  test "family guy sanity check" do
    WORD_SIZE = 6
    ITEM_SIZE = 4
    EPSILON = 0.000001
    
    ##
    ## Begin data setup
    ##
    
    # create words
    bare_words = ["season 1", "season 2", "season 3", "season 4", "season 5", "season 6"]
    for word_idx in 0 .. bare_words.size-1
      Word.new(:word => bare_words[word_idx], :id => word_idx+1).save!
    end
    # can we find our words?
    for word_idx in 0 .. bare_words.size-1
      assert 1 == Word.count(:conditions => ["word = ?", bare_words[word_idx]])
    end
    
    # create items
    feed = Feed.new(:id => 1, :title => 'Family Guy Test', :link => 'http://www.igvita.com/2007/01/15/svd-recommendation-system-in-ruby/')
    feed.save!
    titles = ["Ben", "Tom", "John", "Fred"]
    for item_idx in 0 .. titles.size-1
      Item.new(:title => titles[item_idx], :feed_id => feed.id).save!
    end
    # can we find our items?
    for item_idx in 0 .. titles.size-1
      assert 1 == Item.count(:conditions => ["title = ?", titles[item_idx]])
    end
    
    # create item_words
    doc_structure = Linalg::DMatrix[
    #Ben, Tom, John, Fred
    [5,5,0,5], # season 1
    [5,0,3,4], # season 2
    [3,4,0,3], # season 3
    [0,0,5,3], # season 4
    [5,4,4,5], # season 5
    [5,4,5,5]  # season 6
    ]
    
    # assert right shape
    assert doc_structure.vsize == WORD_SIZE
    assert doc_structure.hsize == ITEM_SIZE
    
    for item_idx in 0 .. ITEM_SIZE-1
      col = doc_structure.column(item_idx)
      item = Item.find(:first, :conditions => ["title = ?", titles[item_idx]])
      for word_idx in 0 .. WORD_SIZE-1
        count = col[word_idx]
        if count > 0
          word = Word.find(:first, :conditions => ["word = ?", bare_words[word_idx]])
          ItemWord.new(:item_id => item.id, :word_id => word.id, :count => col[word_idx]).save!
        end
      end
    end
    
    # can we find our item_words?  do they have the right counts?
    for item_idx in 0 .. ITEM_SIZE-1
      col = doc_structure.column(item_idx)
      item = Item.find(:first, :conditions => ["title = ?", titles[item_idx]])
      for word_idx in 0 .. WORD_SIZE-1
        word = Word.find(:first, :conditions => ["word = ?", bare_words[word_idx]])
        iw = ItemWord.find(:first, :conditions => ["item_id = ? and word_id = ?", item.id, word.id])
        count = col[word_idx]
        if count == 0
          assert iw.nil?
        else
          assert count == iw.count
        end
      end
    end
    
    ##
    ## Begin matrix builder checks
    ##
    
    mb = Classy::MatrixBuilder.new()
    for item_idx in 0 .. titles.size-1
      item = Item.find(:first, :conditions => ["title = ?", titles[item_idx]])
      mb.add_to_a(item)
    end
    
    # now for the truth -- must match rows (or columns) individually, specific row/column order not guaranteed
    for word_idx in 0 .. bare_words.size-1
      assert mb.term_count_row(bare_words[word_idx]) == doc_structure.row(word_idx)
    end
    
    # tf-idf check
    tf_idf = Linalg::DMatrix[
    [0.062540,0.084612,0.000000,0.057536],
    [0.062540,0.000000,0.050767,0.046029],
    [0.037524,0.067690,0.000000,0.034522],
    [0.000000,0.000000,0.203867,0.083178],
    [0.000000,0.000000,0.000000,0.000000],
    [0.000000,0.000000,0.000000,0.000000],
    ]
    for word_idx in 0 .. bare_words.size-1
      assert mb.tf_idf_row(bare_words[word_idx]).within(EPSILON, tf_idf.row(word_idx))
    end
    
    # q test
    q = Linalg::DMatrix[[5,5,0,0,0,5]]
    item = Item.new(:title => "Bob", :feed_id => feed.id)
    item.save!
    for word_idx in 0 .. WORD_SIZE-1
      count = q[0,word_idx]
      if count > 0
        word = Word.find(:first, :conditions => ["word = ?", bare_words[word_idx]])
        ItemWord.new(:item_id => item.id, :word_id => word.id, :count => count).save!
      end
    end
    
    mb_q = mb.q_term_count(item)
    for word_idx in 0 .. bare_words.size-1
      term_idx = mb.get_term_index(bare_words[word_idx])
      assert q[0,word_idx] == mb_q[0,term_idx]
    end
    
    q_tf_idf = Linalg::DMatrix[[0.095894,0.095894,0.000000,0.000000,0.000000,0.000000]]
    mb_q = mb.q_tf_idf(item)
    for word_idx in 0 .. bare_words.size-1
      term_idx = mb.get_term_index(bare_words[word_idx])
      assert q_tf_idf[0,word_idx] >= mb_q[0,term_idx]-EPSILON
      assert q_tf_idf[0,word_idx] <= mb_q[0,term_idx]+EPSILON
    end
    
    ##
    ## the decision section, commented out because order matters and the results will never quite match
    ##
    
    #u,s,vt = mb.a_term_count.singular_value_decomposition
    #u,s,vt = mb.a_tf_idf.singular_value_decomposition
    #u2 = Linalg::DMatrix.join_columns [u.column(0), u.column(1)]
    #v2 = Linalg::DMatrix.join_columns [vt.column(0), vt.column(1)]
    #eig2 = Linalg::DMatrix.columns [s.column(0).to_a.flatten[0,2], s.column(1).to_a.flatten[0,2]]
    #qEmbed = q * u2 * eig2.inverse
    #user_sim, count = {}, 1
    #v2.rows.each { |x|
    #  user_sim[count] = (qEmbed.transpose.dot(x.transpose)) / (x.norm * qEmbed.norm)
    #  count += 1
    #}
    #similar_users = user_sim.delete_if {|k,sim| sim < 0.9 }.sort {|a,b| b[1] <=> a[1] }
    #user_sim.each { |u| printf "%s (ID: %d, Similarity: %0.3f) \n", users[u[0]], u[0], u[1]  }
 

    
  end
end
