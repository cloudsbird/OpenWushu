# A routine's demonstration video can be a YouTube video instead of an upload
class AddYoutubeIdToRoutines < ActiveRecord::Migration[8.1]
  def change
    add_column :routines, :youtube_id, :string
  end
end
