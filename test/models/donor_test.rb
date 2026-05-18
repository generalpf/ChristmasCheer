require "test_helper"

class DonorTest < ActiveSupport::TestCase
  test "returns associated affiliate, category, and courtesy_title" do
    donor = donors(:jane_smith)
    assert_equal affiliates(:brandon_cc), donor.affiliate
    assert_equal categories(:individual), donor.category
    assert_equal courtesy_titles(:ms), donor.courtesy_title
    assert_equal city_towns(:brandon), donor.city_town
  end

  test "city_town association is optional" do
    donor = donors(:john_no_city)
    assert_nil donor.city_town
    assert donor.valid?
  end

  test "requires affiliate" do
    donor = Donor.new(category: categories(:individual), courtesy_title: courtesy_titles(:mr))
    assert_not donor.valid?
    assert_includes donor.errors[:affiliate], "must exist"
  end

  test "requires category" do
    donor = Donor.new(affiliate: affiliates(:brandon_cc), courtesy_title: courtesy_titles(:mr))
    assert_not donor.valid?
    assert_includes donor.errors[:category], "must exist"
  end

  test "requires courtesy_title" do
    donor = Donor.new(affiliate: affiliates(:brandon_cc), category: categories(:individual))
    assert_not donor.valid?
    assert_includes donor.errors[:courtesy_title], "must exist"
  end

  test "FK violation raises on bogus affiliate_id" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      Donor.connection.execute(
        "INSERT INTO donors (affiliate_id, category_id, courtesy_title_id, created_at, updated_at) " \
        "VALUES (9999, 4, 6, NOW(), NOW())"
      )
    end
  end

  test "FK violation raises on bogus city_town_id" do
    donor = Donor.new(
      affiliate: affiliates(:brandon_cc),
      category: categories(:individual),
      courtesy_title: courtesy_titles(:mr)
    )
    donor.city_town_id = 9999
    assert_raises(ActiveRecord::InvalidForeignKey) { donor.save(validate: false) }
  end

  test "invalid when first_name, last_name, and company are all blank" do
    donor = build_donor
    assert_not donor.valid?
    assert_includes donor.errors[:base], "must have both a first and last name, or a company"
  end

  test "invalid with only a first name" do
    donor = build_donor(first_name: "Pat")
    assert_not donor.valid?
    assert_includes donor.errors[:base], "must have both a first and last name, or a company"
  end

  test "invalid with only a last name" do
    donor = build_donor(last_name: "Lee")
    assert_not donor.valid?
    assert_includes donor.errors[:base], "must have both a first and last name, or a company"
  end

  test "valid with first and last name together" do
    assert build_donor(first_name: "Pat", last_name: "Lee").valid?
  end

  test "valid with company alone" do
    assert build_donor(company: "Acme Co").valid?
  end

  test "valid with first, last, and company all set" do
    assert build_donor(first_name: "Pat", last_name: "Lee", company: "Lee Holdings").valid?
  end

  test "previously valid fixture donor remains valid" do
    assert donors(:jane_smith).reload.valid?
  end

  private
    def build_donor(**attrs)
      Donor.new({
        affiliate: affiliates(:brandon_cc),
        category: categories(:individual),
        courtesy_title: courtesy_titles(:mr)
      }.merge(attrs))
    end
end
