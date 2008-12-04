require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "default users" do
    assert_equal "nick", User.find(1).nickname
    assert_equal "keith", User.find(2).nickname
    assert_equal "janko", User.find(3).nickname
  end
end
