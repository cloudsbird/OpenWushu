require "test_helper"

class MovementSearchTest < ActiveSupport::TestCase
  test "finds by pinyin without tone marks, Chinese and translation" do
    assert_equal [ movements(:grasp_right) ], MovementSearch.new("lan que wei").results
    assert_equal [ movements(:grasp_right) ], MovementSearch.new("揽雀尾").results
    assert_equal [ movements(:grasp_right) ], MovementSearch.new("ekor burung").results
  end

  test "blank query finds nothing" do
    assert_empty MovementSearch.new("  ").results
  end
end
