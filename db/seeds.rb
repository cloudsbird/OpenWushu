# Idempotent: safe to run again after editing db/seeds/routines.json.
# Movement names, order and section breaks are facts checked against the reference book;
# descriptions are written in our own words and cite the book's pages (see design/DESIGN.md).
data = JSON.parse(File.read(Rails.root.join("db/seeds/routines.json")))

ActiveRecord::Base.transaction do
  routine = Routine.find_or_initialize_by(slug: data["routine"]["slug"])
  routine.update!(data["routine"])

  data["movements"].each do |attrs|
    routine.movements.find_or_initialize_by(number: attrs["number"]).update!(attrs)
  end

  data["others"].each do |attrs|
    Routine.find_or_initialize_by(slug: attrs["slug"]).update!(attrs)
  end
end

puts "Seeded #{Routine.count} routines and #{Movement.count} movements."
