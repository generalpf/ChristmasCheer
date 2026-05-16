class Category < ApplicationRecord
  has_many :donors, dependent: :restrict_with_exception
end
