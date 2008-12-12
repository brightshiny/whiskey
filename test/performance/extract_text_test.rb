require 'test_helper'
require 'performance_test_help'
require 'benchmark'
include Benchmark

class ExtractTextTest < ActionController::PerformanceTest
  def test_performance
    test_data = ''
    open('data/extract_text_test.txt') {|f| test_data = f.read }
    
    bm(10) do |bm|
      bm.report("extract") { 5.times { Gobbler::GItem.extract_text(test_data) } }
    end
  end
  
end