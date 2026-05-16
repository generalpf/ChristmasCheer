class CreateReferenceTables < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliates do |t|
      t.string :name, null: false
    end

    create_table :categories do |t|
      t.string :name, null: false
    end

    create_table :courtesy_titles do |t|
      t.string :title, null: false
    end

    create_table :payments do |t|
      t.string :name, null: false
    end

    create_table :publications do |t|
      t.string :name, null: false
    end

    create_table :sources do |t|
      t.string :name, null: false
    end
  end
end
