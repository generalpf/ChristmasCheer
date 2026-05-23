module DonorsHelper
  def donor_display_name(donor)
    return "" if donor.nil?

    full_name = [ donor.first_name, donor.last_name ].compact_blank.join(" ")
    return full_name if donor.first_name.present? && donor.last_name.present?
    return donor.company if donor.company.present?
    return full_name if full_name.present?

    "Donor ##{donor.id}"
  end
end
