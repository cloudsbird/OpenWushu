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

  test "a YouTube link plays on the Learn tab and can be removed" do
    routine = routines(:taiji)
    patch admin_routine_path(routine), params: { routine: { youtube_url: "https://youtu.be/dQw4w9WgXcQ?si=abc" } }
    assert_redirected_to admin_routines_path
    assert_equal "dQw4w9WgXcQ", routine.reload.youtube_id

    get routine_path(routine)
    assert_select ".stage.has-video [data-routine-player-target=youtube][data-video-id=dQw4w9WgXcQ]"
    assert_select "video", 0

    patch admin_routine_path(routine), params: { routine: { youtube_url: "" } }
    assert_nil routine.reload.youtube_id
  end

  test "a link that is not a YouTube video is refused" do
    patch admin_routine_path(routines(:taiji)), params: { routine: { youtube_url: "https://vimeo.com/123" } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /YouTube/
    assert_select "input[name='routine[youtube_url]'][value='https://vimeo.com/123']"
    assert_nil routines(:taiji).reload.youtube_id
  end

  test "a YouTube link fills the credit shown under the video" do
    Routine.youtube_lookup = ->(_id) { YoutubeVideo::Details.new(title: "42式太极拳", author: "Wushu Club", author_url: "https://www.youtube.com/@wushuclub") }
    routine = routines(:taiji)
    patch admin_routine_path(routine), params: { routine: { youtube_url: "https://youtu.be/dQw4w9WgXcQ" } }
    assert_redirected_to admin_routines_path
    assert_equal [ "42式太极拳", "Wushu Club" ], [ routine.reload.video_title, routine.video_author ]

    get routine_path(routine)
    assert_select ".video-credit a[href='https://www.youtube.com/@wushuclub']", "Wushu Club"
    assert_select ".video-credit a[href='https://www.youtube.com/watch?v=dQw4w9WgXcQ']"

    patch admin_routine_path(routine), params: { routine: { youtube_url: "" } }
    assert_nil routine.reload.video_author
  end

  test "a video whose owner does not allow embedding is refused" do
    Routine.youtube_lookup = ->(_id) { :not_embeddable }
    patch admin_routine_path(routines(:taiji)), params: { routine: { youtube_url: "https://youtu.be/dQw4w9WgXcQ" } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /does not allow/
    assert_nil routines(:taiji).reload.youtube_id
  end

  test "set the movement timings" do
    routine = routines(:taiji)
    get timings_admin_routine_path(routine)
    assert_select "input[name='timings[starts][1]']"
    assert_select "input[name='timings[finish]'][data-key=end]"
    assert_select "input[name='timings[starts][1]'][data-key='1']"
    assert_select "textarea[data-timing-editor-target=paste]"

    patch timings_admin_routine_path(routine), params: { timings: { starts: { "1" => "2.5", "2" => "11" }, finish: "20.4" } }
    assert_redirected_to timings_admin_routine_path(routine)
    assert_equal [ [ 2.5, 11.0 ], [ 11.0, 20.4 ] ], routine.movements.map { |m| [ m.start_sec, m.end_sec ] }
  end

  test "timings out of order are refused" do
    routine = routines(:taiji)
    patch timings_admin_routine_path(routine), params: { timings: { starts: { "1" => "12", "2" => "4" }, finish: "20" } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /not earlier/
    assert_select "input[name='timings[starts][1]'][value='12']"
    assert_equal 0, routine.movements.first.reload.start_sec
  end

  test "only MP4 or WebM" do
    patch admin_routine_path(routines(:taiji)), params: { routine: { video: fixture_file_upload("notes.txt", "text/plain") } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /MP4 or WebM/
    assert_not routines(:taiji).reload.video.attached?
  end
end
