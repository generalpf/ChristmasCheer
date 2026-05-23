class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :donor, null: false, foreign_key: true

      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :eligible_amount, precision: 12, scale: 2, null: false, default: 0

      t.bigint :source_id
      t.bigint :payment_id
      t.bigint :publication_id

      t.string :transaction_reference
      t.string :message
      t.string :receipt_num

      t.date :donation_date
      t.date :receipt_date
      t.date :deposit_date

      t.integer :c_receipt_num

      t.boolean :receipt_required,  null: false, default: false
      t.boolean :receipt_pending,   null: false, default: false
      t.boolean :receipt_processed, null: false, default: false
      t.boolean :receipt_replaced,  null: false, default: false

      t.text :notes

      t.timestamps
    end

    add_index :donations, :donation_date
  end
end
