class CreateDonors < ActiveRecord::Migration[8.1]
  def change
    create_table :donors do |t|
      t.references :affiliate, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :courtesy_title, null: false, foreign_key: true
      t.references :city_town, null: true, foreign_key: true

      t.string :first_name
      t.string :spouse
      t.string :last_name
      t.string :job_title
      t.string :company

      t.string :address_line1
      t.string :address_line2
      t.string :province
      t.string :postal_code
      t.string :zip_code

      t.string :phone
      t.string :email1
      t.string :email2

      t.text :notes

      t.timestamps
    end

    add_index :donors, :last_name
    add_index :donors, :company
  end
end
