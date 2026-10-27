require "test_helper"

class Admin::RoutinesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "index lists every routine" do
    get admin_routines_path
    assert_select "tbody tr", Routine.count
  end

  test "change status" do
    patch admin_routine_path(routines(:taiji)), params: { routine: { status: "in_progress" } }
    assert_redirected_to admin_routines_path
    assert_equal "in_progress", routines(:taiji).reload.status
  end

  test "a routine without movements can't be published" do
    patch admin_routine_path(routines(:changquan)), params: { routine: { status: "published" } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /movement list/
    assert_equal "awaiting", routines(:changquan).reload.status
  end

  test "upload, replace and remove the video" do
    routine = routines(:taiji)
    patch admin_routine_path(routine), params: { routine: { video: fixture_file_upload("clip.mp4", "video/mp4") } }
    assert_redirected_to admin_routines_path
    assert routine.reload.video.attached?

    get routine_path(routine)
    assert_select "video[src]"

    delete video_admin_routine_path(routine)
    perform_enqueued_jobs
    assert_not routine.reload.video.attached?
  end

  test "only MP4 or WebM" do
    patch admin_routine_path(routines(:taiji)), params: { routine: { video: fixture_file_upload("notes.txt", "text/plain") } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /MP4 or WebM/
    assert_not routines(:taiji).reload.video.attached?
  end
end
