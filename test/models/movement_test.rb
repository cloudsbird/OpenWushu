require "test_helper"

class MovementTest < ActiveSupport::TestCase
  test "translated names and lists follow the locale" do
    movement = movements(:commencing)
    I18n.with_locale(:en) do
      assert_equal "Commencing Form", movement.name_tr
      assert_equal [ "Stand naturally." ], movement.steps_tr
    end
    I18n.with_locale(:id) do
      assert_equal "Sikap Pembuka", movement.name_tr
      assert_equal [ "Kepala tegak." ], movement.key_points_tr
    end
  end

  test "described only when it has steps" do
    assert movements(:commencing).described?
    assert_not movements(:grasp_right).described?
  end

  test "chinese numbers and section names" do
    assert_equal "二", movements(:grasp_right).cn_number
    assert_equal "第一段", movements(:grasp_right).section_name
    assert_equal({ 1 => "一", 10 => "十", 12 => "十二", 20 => "二十", 42 => "四十二" },
                 [ 1, 10, 12, 20, 42 ].index_with { |n| ChineseNumeral.call(n) })
  end

  test "起势 and 收势 groups keep the book's own numbering" do
    opening = Movement.new(number: 1, section: Movement::OPENING, book_number: 2, name_zh: "并步按掌")
    first_section = Movement.new(number: 3, section: 1, book_number: 1, name_zh: "并步撩掌")
    unnumbered = Movement.new(number: 1, section: Movement::PREPARATION, name_zh: "预备势")
    closing = Movement.new(number: 53, section: Movement::CLOSING, name_zh: "收势")

    assert_equal [ "起势", "二", "第二式" ], [ opening.section_name, opening.cn_number, opening.cn_label ]
    assert_equal [ "第一段", "一", "第一式" ], [ first_section.section_name, first_section.cn_number, first_section.cn_label ]
    assert_equal [ "预备势", "预", "预备势" ], [ unnumbered.section_name, unnumbered.cn_number, unnumbered.cn_label ]
    assert_equal [ "收势", "收", "收势" ], [ closing.section_name, closing.cn_number, closing.cn_label ]
  end

  test "end must not be before start" do
    movement = movements(:grasp_right)
    movement.end_sec = 1
    assert_not movement.valid?
  end

  test "routine duration is the end of its last movement" do
    assert_equal 18, routines(:taiji).duration_sec
  end
end
