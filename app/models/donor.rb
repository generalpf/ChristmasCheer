class Donor < ApplicationRecord
  belongs_to :affiliate
  belongs_to :category
  belongs_to :courtesy_title
  belongs_to :city_town, optional: true

  validate :requires_full_name_or_company

  private
    def requires_full_name_or_company
      return if company.present?
      return if first_name.present? && last_name.present?

      errors.add(:base, "must have both a first and last name, or a company")
    end
end
