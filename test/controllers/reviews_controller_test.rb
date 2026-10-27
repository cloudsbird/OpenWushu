require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @movement = movements(:grasp_right)
    after = @movement.snapshot.merge("steps" => { "en" => [ "New step." ], "id" => [] })
    @revision = @movement.revisions.create!(author: users(:contributor), before: @movement.snapshot, after: after,
                                            summary: "Added a step", source: "Own teaching")
  end

  test "who can see the queue" do
    get reviews_path
    assert_redirected_to new_session_path
    [ :one, :contributor ].each do |name|
      sign_in_as users(name)
      get reviews_path
      assert_response :not_found, name
      post approve_review_path(@revision)
      assert_response :not_found, name
    end
    [ :maintainer, :admin ].each do |name|
      sign_in_as users(name)
      get reviews_path
      assert_response :success, name
      assert_select "a[href=?]", review_path(@revision)
    end
  end

  test "approve publishes, credits the author and emails them" do
    sign_in_as users(:maintainer)
    get review_path(@revision)
    assert_select ".diff__line--ins", "Added: New step."

    post approve_review_path(@revision)
    assert_redirected_to reviews_path
    assert_equal [ "New step." ], @movement.reload.steps["en"]
    assert @revision.reload.published?
    assert_equal users(:maintainer), @revision.reviewer
    assert_enqueued_email_with RevisionMailer, :decided, args: [ @revision ]
  end

  test "approving is blocked when the movement changed since submission" do
    @movement.update!(steps: { "en" => [ "Someone else's edit." ] })
    sign_in_as users(:maintainer)
    get review_path(@revision)
    assert_select "[role=alert]", /edited after/
    post approve_review_path(@revision)
    assert_redirected_to review_path(@revision)
    assert @revision.reload.pending?
    assert_equal [ "Someone else's edit." ], @movement.reload.steps["en"]
  end

  test "request changes and reject need a note" do
    sign_in_as users(:admin)
    post request_changes_review_path(@revision), params: { note: "" }
    assert @revision.reload.pending?

    post request_changes_review_path(@revision), params: { note: "Please cite the page." }
    assert_equal [ "changes_requested", "Please cite the page." ], @revision.reload.values_at(:status, :note)
    assert_enqueued_email_with RevisionMailer, :decided, args: [ @revision ]

    post reject_review_path(@revision), params: { note: "Too late" }
    assert_equal "changes_requested", @revision.reload.status
  end

  test "reject" do
    sign_in_as users(:admin)
    post reject_review_path(@revision), params: { note: "Copied from the book." }
    assert_equal "rejected", @revision.reload.status
    assert_empty @movement.reload.steps.to_h
  end

  test "nobody reviews their own change" do
    users(:contributor).update!(role: "maintainer")
    sign_in_as users(:contributor)
    post approve_review_path(@revision)
    assert_redirected_to review_path(@revision)
    assert @revision.reload.pending?
  end

  test "contributors see their submissions and the reviewer's note" do
    @revision.decide!("changes_requested", reviewer: users(:maintainer), note: "Please cite the page.")
    sign_in_as users(:contributor)
    get contributions_path
    assert_select "td", /Please cite the page/
    assert_select ".badge", "Changes requested"
  end

  test "the header shows the pending count to reviewers" do
    post session_path, params: { email_address: users(:maintainer).email_address, password: "password" }
    get root_path
    assert_select ".site-nav a[href=?] .count-badge", reviews_path, "1"
  end
end
