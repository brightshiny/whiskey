require 'test_helper'
require 'read'

class ReadsControllerTest < ActionController::TestCase
  
  def setup
    super
  end
  
  test "should create read" do
    assert_difference('Read.count') do
      # User 1 -- 9PpPEYPuoEdoc6N3Hc---lFQ
      # Click 1 -- 9PpPEYPuoEdoc6N3Hc---lFQ
      # http://localhost:3000/clicks/create?u=9PpPEYPuoEdoc6N3Hc---lFQ&i=9PpPEYPuoEdoc6N3Hc---lFQ
      post :create, { :u => "9PpPEYPuoEdoc6N3Hc---lFQ", :i => "9PpPEYPuoEdoc6N3Hc---lFQ" }
    end
  end
  
  test "should not create read" do
    assert_no_difference('Read.count') do
      post :create, { :u => 1, :i => 1 }
    end
  end
  
end
