require "test_helper"

class DonorsSchemaTest < ActiveSupport::TestCase
  EXPECTED_COLUMNS = %w[
    address_line1 address_line2 affiliate_id category_id city_town_id company
    courtesy_title_id created_at email1 email2 first_name id job_title last_name
    notes phone postal_code province spouse updated_at zip_code
  ].freeze

  EXPECTED_INDEXED_COLUMNS = %w[
    affiliate_id category_id city_town_id company courtesy_title_id last_name
  ].freeze

  test "donors table has the expected columns" do
    assert_equal EXPECTED_COLUMNS, Donor.column_names.sort
  end

  test "donors has indexes on FKs and lookup columns" do
    indexed_columns =
      ActiveRecord::Base.connection.indexes("donors").map(&:columns).flatten.sort.uniq
    EXPECTED_INDEXED_COLUMNS.each do |col|
      assert_includes indexed_columns, col, "expected index on donors.#{col}"
    end
  end

  test "donors has NOT NULL on required FKs" do
    schema = ActiveRecord::Base.connection.columns("donors").index_by(&:name)
    %w[affiliate_id category_id courtesy_title_id].each do |col|
      assert_equal false, schema.fetch(col).null, "donors.#{col} should be NOT NULL"
    end
    assert_equal true, schema.fetch("city_town_id").null, "donors.city_town_id should be nullable"
  end
end
