# Who made the demonstration video, shown under the player (filled from YouTube for YouTube links)
class AddVideoCreditToRoutines < ActiveRecord::Migration[8.1]
  def change
    add_column :routines, :video_title, :string
    add_column :routines, :video_author, :string
    add_column :routines, :video_author_url, :string
  end
end
