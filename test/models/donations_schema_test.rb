require "test_helper"

class DonationsSchemaTest < ActiveSupport::TestCase
  EXPECTED_COLUMNS = %w[
    amount c_receipt_num created_at deposit_date donation_date donor_id
    eligible_amount id message notes payment_id publication_id receipt_date
    receipt_num receipt_pending receipt_processed receipt_replaced
    receipt_required source_id transaction_reference updated_at
  ].freeze

  EXPECTED_INDEXED_COLUMNS = %w[donation_date donor_id].freeze

  test "donations table has the expected columns" do
    assert_equal EXPECTED_COLUMNS, Donation.column_names.sort
  end

  test "donations has indexes on donor_id and donation_date" do
    indexed_columns =
      ActiveRecord::Base.connection.indexes("donations").map(&:columns).flatten.sort.uniq
    EXPECTED_INDEXED_COLUMNS.each do |col|
      assert_includes indexed_columns, col, "expected index on donations.#{col}"
    end
  end

  test "donor_id is NOT NULL; deferred FK columns are nullable" do
    schema = ActiveRecord::Base.connection.columns("donations").index_by(&:name)
    assert_equal false, schema.fetch("donor_id").null, "donations.donor_id should be NOT NULL"
    %w[source_id payment_id publication_id].each do |col|
      assert_equal true, schema.fetch(col).null, "donations.#{col} should be nullable"
    end
  end

  test "money columns are NOT NULL with default zero" do
    schema = ActiveRecord::Base.connection.columns("donations").index_by(&:name)
    %w[amount eligible_amount].each do |col|
      column = schema.fetch(col)
      assert_equal false, column.null, "donations.#{col} should be NOT NULL"
      assert_equal 0, column.default.to_f, "donations.#{col} should default to 0"
    end
  end

  test "receipt_* booleans are NOT NULL with default false" do
    schema = ActiveRecord::Base.connection.columns("donations").index_by(&:name)
    %w[receipt_required receipt_pending receipt_processed receipt_replaced].each do |col|
      column = schema.fetch(col)
      assert_equal false, column.null, "donations.#{col} should be NOT NULL"
      assert_equal false, ActiveModel::Type::Boolean.new.cast(column.default),
        "donations.#{col} should default to false"
    end
  end

  test "no FK constraints on source_id, payment_id, publication_id" do
    fk_columns = ActiveRecord::Base.connection.foreign_keys("donations").map(&:column)
    %w[source_id payment_id publication_id].each do |col|
      assert_not_includes fk_columns, col, "donations.#{col} should not have an FK constraint yet"
    end
    assert_includes fk_columns, "donor_id", "donations.donor_id should have an FK constraint"
  end
end
