require "test_helper"

class RevisionTest < ActiveSupport::TestCase
  setup { @movement = movements(:commencing) }

  def build(after_changes)
    @movement.revisions.new(author: users(:contributor), summary: "Edit", source: "Book",
                            before: @movement.snapshot, after: @movement.snapshot.merge(after_changes))
  end

  test "changed_fields and stale?" do
    revision = build("name_en" => "Opening")
    revision.save!
    assert_equal %w[name_en], revision.changed_fields
    assert_not revision.stale?

    @movement.update!(steps: { "en" => [ "Other." ] })
    assert_not revision.stale?, "a change to another field doesn't matter"
    @movement.update!(name_en: "Beginning")
    assert revision.stale?
    assert_raises(Revision::Stale) { revision.publish!(users(:admin)) }
  end

  test "limits on list length and line length" do
    assert_not build("steps" => { "en" => Array.new(31, "x"), "id" => [] }).valid?
    assert_not build("steps" => { "en" => [ "x" * 601 ], "id" => [] }).valid?
    assert build("steps" => { "en" => [ "x" * 600 ], "id" => [] }).valid?
  end

  test "snapshot shapes lists with both languages" do
    assert_equal({ "en" => [], "id" => [] }, movements(:grasp_right).snapshot["steps"])
  end
end
