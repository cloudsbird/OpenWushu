# Loads db/seeds/routines/<slug>.json, one file per routine of the IWUF 1st compulsory routines
# (the B Junior book). Safe to run again: it creates what is missing and fills fields that are
# still blank, but never overwrites text, statuses or videos already edited in the app
# (revisions, admin panel). Movement names, order and section breaks are facts checked against
# the book; descriptions are written in our own words and cite its pages (see design/DESIGN.md).
fillable = %w[facing_en facing_id steps key_points mistakes reference]
routine_fillable = %w[card_zh reference_page reference_figure]
blank = ->(value) { value.blank? || (value.is_a?(Hash) && value.values.all?(&:blank?)) }
old_source = "Competition routines collection (scan)"
source = "IWUF 1st Compulsory Routines (B Junior)"

ActiveRecord::Base.transaction do
  # The book was first cited before its title was known
  Movement.where("reference LIKE ?", "#{old_source}%").update_all([ "reference = replace(reference, ?, ?)", old_source, source ])
  # 长拳 was first translated as "Changquan"; it is now Northern Fist / Tinju Utara
  Routine.where(slug: "changquan", name_en: "Changquan").update_all(name_en: "Northern Fist", name_id: "Tinju Utara")
  Movement.where("reference LIKE ?", "%, Changquan, p.%").update_all([ "reference = replace(reference, ?, ?)", ", Changquan, p.", ", Northern Fist, p." ])

  Dir[Rails.root.join("db/seeds/routines/*.json")].sort.each do |path|
    data = JSON.parse(File.read(path))
    attrs = data["routine"]
    routine = Routine.create_with(attrs.except("status")).find_or_create_by!(slug: attrs["slug"])
    routine_blanks = routine_fillable.select { |field| attrs[field].present? && routine[field].blank? }
    routine.update!(attrs.slice(*routine_blanks)) if routine_blanks.any?

    data["movements"].each do |move|
      movement = routine.movements.create_with(move).find_or_create_by!(number: move["number"])
      blanks = fillable.select { |field| move[field].present? && blank.(movement[field]) }
      movement.update!(move.slice(*blanks)) if blanks.any?
    end

    # A routine opens once it has its movement list, unless an admin has already set its status
    status = routine.movements.exists? ? "published" : attrs.fetch("status", "awaiting")
    routine.update!(status: status) if routine.status == "awaiting" || (routine.status == "in_progress" && status == "published")
  end
end

puts "Seeded #{Routine.count} routines and #{Movement.count} movements."
