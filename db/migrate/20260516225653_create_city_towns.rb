class CreateCityTowns < ActiveRecord::Migration[8.1]
  def change
    create_table :city_towns do |t|
      t.string :name, null: false
    end
  end
end
