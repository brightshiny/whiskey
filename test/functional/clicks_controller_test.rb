require 'test_helper'

class ClicksControllerTest < ActionController::TestCase
  
  def setup
    super
  end
  
  test "should create click" do
    assert_difference('Click.count') do
      # User 1 -- 9PpPEYPuoEdoc6N3Hc---lFQ
      # Click 1 -- 9PpPEYPuoEdoc6N3Hc---lFQ
      post :create, { :u => "9PpPEYPuoEdoc6N3Hc---lFQ", :i => "9PpPEYPuoEdoc6N3Hc---lFQ" }
    end
  end
  
  test "should not create click" do
    assert_no_difference('Click.count') do
      post :create, { :u => 1, :i => 1 }
    end
  end

end
