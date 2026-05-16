# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Single operator account. The Christmas Cheer app has one human user (the volunteer
# maintaining donor data). Set OPERATOR_EMAIL and OPERATOR_PASSWORD before running
# `bin/rails db:seed` to provision (or update) the account. Re-runs are safe.
operator_email = ENV["OPERATOR_EMAIL"]
operator_password = ENV["OPERATOR_PASSWORD"]

if operator_email.present? && operator_password.present?
  user = User.find_or_initialize_by(email_address: operator_email)
  user.password = operator_password
  user.save!
  puts "Operator account ready: #{operator_email}"
else
  puts "Skipping operator seed (OPERATOR_EMAIL and OPERATOR_PASSWORD not set)."
end

# Reference tables — seeded with exact Access originals. IDs are preserved so future
# donor/donation imports can use Access foreign key values verbatim.

def seed_reference_table(model_class, rows, value_column: :name)
  model_class.upsert_all(rows, unique_by: :id)
  max_id = rows.max_by { |r| r[:id] }[:id]
  table = model_class.quoted_table_name
  ActiveRecord::Base.connection.execute(
    "SELECT setval(pg_get_serial_sequence('#{model_class.table_name}', 'id'), #{max_id})"
  )
  puts "#{model_class}: #{rows.size} rows seeded (max id=#{max_id})"
end

seed_reference_table Affiliate, [
  { id: 1, name: "BoissevainCC" },
  { id: 2, name: "BrandonCC" },
  { id: 3, name: "DeloraineCC" },
  { id: 4, name: "EOS_CC" },
  { id: 5, name: "MelitaCC" },
  { id: 6, name: "RiversCC" },
  { id: 7, name: "VirdenCC" }
]

seed_reference_table Category, [
  { id: 1, name: "Business" },
  { id: 2, name: "Government" },
  { id: 3, name: "Group/Organization" },
  { id: 4, name: "Individual" },
  { id: 5, name: "Other (Specify in Notes)" },
  { id: 6, name: "VOID Receipt" }
]

CourtesyTitle.upsert_all([
  { id: 1, title: "Dr." },
  { id: 2, title: "Dr. & Mrs." },
  { id: 3, title: "Fr." },
  { id: 4, title: "Minister" },
  { id: 5, title: "Miss" },
  { id: 6, title: "Mr." },
  { id: 7, title: "Mr. & Mrs." },
  { id: 8, title: "Mrs." },
  { id: 9, title: "Ms." },
  { id: 10, title: "To Whom It May Concern" },
  { id: 11, title: "None" }
], unique_by: :id)
ActiveRecord::Base.connection.execute(
  "SELECT setval(pg_get_serial_sequence('courtesy_titles', 'id'), 11)"
)
puts "CourtesyTitle: 11 rows seeded (max id=11)"

seed_reference_table Payment, [
  { id: 1, name: "Cash" },
  { id: 2, name: "Cheque" },
  { id: 3, name: "EFT" },
  { id: 4, name: "Gift Card" },
  { id: 5, name: "Gift in Kind" },
  { id: 6, name: "Other (Specify in Notes)" },
  { id: 7, name: "Square" }
]

seed_reference_table Publication, [
  { id: 1, name: "Anonymous" },
  { id: 2, name: "Business Name" },
  { id: 3, name: "Canadian Tire Customers" },
  { id: 4, name: "Fill the Bus-Safeway Customers" },
  { id: 5, name: "Fill the Bus-Sobeys West Customers" },
  { id: 6, name: "Name as Written" },
  { id: 7, name: "None" },
  { id: 8, name: "Other (Specify in Message)" },
  { id: 9, name: "UCT Bingo Players" }
]

# TODO: city_towns seed — Access `CityTownT` row list pending. When supplied, add an
# idempotent seed block here (explicit IDs via `upsert_all`, sequence reset after),
# mirroring the pattern used for the other reference tables. Tracked in the
# `add-donors-table` change; the table exists but is intentionally empty for now.

seed_reference_table Source, [
  { id: 1,  name: "DeloraineCC" },
  { id: 2,  name: "Benevity" },
  { id: 3,  name: "CanadaHelps" },
  { id: 4,  name: "Canadian Tire" },
  { id: 5,  name: "CC Office" },
  { id: 6,  name: "e-Transfer" },
  { id: 7,  name: "Fill the Bus" },
  { id: 8,  name: "Mail" },
  { id: 9,  name: "Other (Specify in Notes)" },
  { id: 10, name: "PayPal" },
  { id: 11, name: "UCT Bingo" },
  { id: 12, name: "BoissevainCC" },
  { id: 13, name: "MelitaCC" },
  { id: 14, name: "RiversCC" },
  { id: 15, name: "EOS_CC" },
  { id: 16, name: "VirdenCC" }
]
