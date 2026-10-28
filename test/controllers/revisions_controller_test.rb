require "test_helper"

class RevisionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @routine = routines(:taiji)
    @movement = movements(:grasp_right)
  end

  def form(**overrides)
    { revision: { name_en: @movement.name_en, name_id: @movement.name_id,
                  steps_en: "Turn the body right.\n\nShift weight forward.", steps_id: "Putar badan ke kanan.",
                  summary: "Wrote the steps", source: "IWUF 1st Compulsory Routines (B Junior), p. 600" }.merge(overrides) }
  end

  test "the history is public and lists published revisions" do
    get routine_movement_revisions_path(@routine, @movement)
    assert_response :success
    assert_select ".history__item", 1 # only the original text
  end

  test "visitors are asked to sign in to edit; members get a 404" do
    get new_routine_movement_revision_path(@routine, @movement)
    assert_redirected_to new_session_path

    sign_in_as users(:one)
    get new_routine_movement_revision_path(@routine, @movement)
    assert_response :not_found
    post routine_movement_revisions_path(@routine, @movement), params: form
    assert_response :not_found
  end

  test "a contributor's change waits for review and emails the reviewers" do
    sign_in_as users(:contributor)
    get new_routine_movement_revision_path(@routine, @movement)
    assert_response :success

    assert_difference -> { Revision.pending.count } do
      post routine_movement_revisions_path(@routine, @movement), params: form
    end
    assert_redirected_to contributions_path
    revision = Revision.last
    assert_equal [ "Turn the body right.", "Shift weight forward." ], revision.after.dig("steps", "en")
    assert_equal %w[steps], revision.changed_fields
    assert_empty @movement.reload.steps.to_h
    assert_enqueued_email_with RevisionMailer, :submitted, args: [ revision, users(:admin) ]
    assert_enqueued_email_with RevisionMailer, :submitted, args: [ revision, users(:maintainer) ]
  end

  test "a maintainer's change is published at once and shows in the Learn detail and history" do
    sign_in_as users(:maintainer)
    post routine_movement_revisions_path(@routine, @movement), params: form
    assert_redirected_to routine_path(@routine, m: 2)
    assert_equal [ "Putar badan ke kanan." ], @movement.reload.steps["id"]
    revision = Revision.last
    assert revision.published?
    assert_equal users(:maintainer), revision.reviewer

    get routine_path(@routine, m: 2)
    assert_select "article[data-n='2'] .steps li", 2
    assert_select "article[data-n='2'] .detail__footer a", /1 revision/
    get routine_movement_revisions_path(@routine, @movement)
    assert_select ".history__summary", "Wrote the steps"
    assert_select ".diff__line--ins", /Turn the body right/
  end

  test "submitting needs a summary, a source and some change" do
    sign_in_as users(:contributor)
    post routine_movement_revisions_path(@routine, @movement), params: form(summary: "", source: "")
    assert_response :unprocessable_entity
    assert_select "[role=alert] p", 2

    post routine_movement_revisions_path(@routine, @movement), params: form(steps_en: "", steps_id: "")
    assert_response :unprocessable_entity
    assert_select "[role=alert]", /Nothing was changed/

    post routine_movement_revisions_path(@routine, @movement), params: form(name_en: "")
    assert_select "[role=alert]", /names can’t be empty/
  end

  test "an unverified contributor is asked to verify when the site requires it" do
    users(:contributor).update!(verified_at: nil)
    sign_in_as users(:contributor)
    get new_routine_movement_revision_path(@routine, @movement)
    assert_redirected_to email_verification_path

    Setting.current.update!(verification_required: false)
    get new_routine_movement_revision_path(@routine, @movement)
    assert_response :success
  end

  test "restore saves an earlier version as a new revision" do
    sign_in_as users(:maintainer)
    post routine_movement_revisions_path(@routine, @movement), params: form
    first = Revision.last
    post routine_movement_revisions_path(@routine, @movement), params: form(steps_en: "Something else.", summary: "Rewrote")

    post restore_routine_movement_revision_path(@routine, @movement, first)
    assert_equal [ "Turn the body right.", "Shift weight forward." ], @movement.reload.steps["en"]
    assert_equal first, Revision.last.restored_from
    assert_equal "Restored version r1", Revision.last.summary
    assert_equal 3, @movement.revisions.published.count

    post restore_routine_movement_revision_path(@routine, @movement, first, to: "before")
    assert_empty @movement.reload.steps.to_h.values.flatten

    post restore_routine_movement_revision_path(@routine, @movement, first, to: "before")
    follow_redirect!
    assert_select "[role=alert]", /already matches/
  end

  test "contributors can't restore" do
    sign_in_as users(:maintainer)
    post routine_movement_revisions_path(@routine, @movement), params: form
    sign_in_as users(:contributor)
    post restore_routine_movement_revision_path(@routine, @movement, Revision.last, to: "before")
    assert_response :not_found
  end

  # Through the real sign-in form, so nothing is preloaded in Current
  test "the edit link shows in the Learn detail for contributors only" do
    post session_path, params: { email_address: users(:contributor).email_address, password: "password" }
    get routine_path(@routine)
    assert_select "a[href=?]", new_routine_movement_revision_path(@routine, movements(:commencing))
    assert_select ".site-nav a[href=?]", contributions_path

    delete session_path
    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    get routine_path(@routine)
    assert_select "a[href=?]", new_routine_movement_revision_path(@routine, movements(:commencing)), count: 0
  end

  test "maintainers signed in through the form see Restore on the public history page" do
    sign_in_as users(:maintainer)
    post routine_movement_revisions_path(@routine, @movement), params: form
    post routine_movement_revisions_path(@routine, @movement), params: form(steps_en: "Other.", summary: "Rewrote")
    delete session_path

    post session_path, params: { email_address: users(:maintainer).email_address, password: "password" }
    get routine_movement_revisions_path(@routine, @movement)
    assert_select "button", text: "Restore this version", count: 2
  end
end
