class Donor < ApplicationRecord
  belongs_to :affiliate
  belongs_to :category
  belongs_to :courtesy_title
  belongs_to :city_town, optional: true
end
