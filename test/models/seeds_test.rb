require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  SEED_FILES = Dir[Rails.root.join("db/seeds/routines/*.json")].sort

  def run_seeds
    capture_io { load Rails.root.join("db/seeds.rb") }
  end

  test "every routine file numbers its movements 1..n with both translations" do
    assert_equal 10, SEED_FILES.size
    SEED_FILES.each do |path|
      movements = JSON.parse(File.read(path))["movements"]
      assert_equal (1..movements.size).to_a, movements.map { |m| m["number"] }, path
      movements.each do |m|
        %w[name_zh name_pinyin name_en name_id].each { |field| assert m[field].present?, "#{path} ##{m["number"]} #{field}" }
        %w[steps key_points].each do |list|
          assert_equal m[list]["en"].size, m[list]["id"].size, "#{path} ##{m["number"]} #{list}"
        end
      end
    end
  end

  test "seeding fills blanks, publishes routines with movements and can run twice" do
    commencing = movements(:commencing)
    run_seeds
    run_seeds

    assert_equal [ "Stand naturally." ], commencing.reload.steps["en"], "text edited in the app is kept"
    assert movements(:grasp_right).reload.described?, "blank movements are filled from the seed"

    changquan = Routine.find_by!(slug: "changquan")
    assert changquan.published?
    assert_equal "长", changquan.card_zh
    assert_equal 62, changquan.movements.count
    assert_equal 4, changquan.section_count
    assert_equal 10, Routine.published.count
  end
end
