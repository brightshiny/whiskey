require 'test_helper'

class FeedTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "default feed sanity" do
    feed = Feed.find(1)
    assert_not_nil feed
    assert_equal "TechCrunch", feed.title
    assert_not_nil feed.link
    assert_not_equal '', feed.link
  end
end
