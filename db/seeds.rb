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
