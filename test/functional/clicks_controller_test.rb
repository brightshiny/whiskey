require 'test_helper'

class ClicksControllerTest < ActionController::TestCase

  test "should create click" do
    assert_difference('Click.count') do
      post :create, { :u => "9PpPEYPuoEdoc6N3Hc---lFQ", :i => "9PpPEYPuoEdoc6N3Hc---lFQ" }
    end
  end

end
