require "test_helper"

class RoutineTest < ActiveSupport::TestCase
  test "reads the video ID from common YouTube links" do
    {
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/watch?feature=share&v=dQw4w9WgXcQ&t=42" => "dQw4w9WgXcQ",
      "https://m.youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtu.be/dQw4w9WgXcQ?si=abc" => "dQw4w9WgXcQ",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/embed/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/live/dQw4w9WgXcQ?feature=share" => "dQw4w9WgXcQ",
      "dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://vimeo.com/123456" => nil,
      "https://www.youtube.com/watch?v=short" => nil,
      "https://evil.example/watch?v=dQw4w9WgXcQ" => nil,
      "not a link" => nil
    }.each do |url, id|
      assert_equal id, Routine.youtube_id_from(url), url
    end
  end

  test "video credit is trimmed" do
    routine = Routine.new(video_title: "  Women's 42 Movements Taijijian ", video_author: " WUSHU TV ", video_author_url: "  ")
    assert_equal [ "Women's 42 Movements Taijijian", "WUSHU TV", nil ], [ routine.video_title, routine.video_author, routine.video_author_url ]
  end

  test "an uploaded video takes priority over YouTube" do
    routine = routines(:taiji)
    routine.youtube_url = "https://youtu.be/dQw4w9WgXcQ"
    assert routine.youtube?
    assert routine.video?

    routine.video.attach(io: StringIO.new("x"), filename: "clip.mp4", content_type: "video/mp4")
    assert_not routine.youtube?
  end
end
