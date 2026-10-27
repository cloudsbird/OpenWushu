# Creates the routines and movements that are missing; never changes existing ones, because their
# texts, statuses and videos are edited in the app (revisions, admin panel) after the first seed.
# Movement names, order and section breaks are facts checked against the reference book;
# descriptions are written in our own words and cite the book's pages (see design/DESIGN.md).
data = JSON.parse(File.read(Rails.root.join("db/seeds/routines.json")))

ActiveRecord::Base.transaction do
  routine = Routine.create_with(data["routine"]).find_or_create_by!(slug: data["routine"]["slug"])

  data["movements"].each do |attrs|
    routine.movements.create_with(attrs).find_or_create_by!(number: attrs["number"])
  end

  data["others"].each do |attrs|
    Routine.create_with(attrs).find_or_create_by!(slug: attrs["slug"])
  end
end

puts "Seeded #{Routine.count} routines and #{Movement.count} movements."
