require "test_helper"

class DonationTest < ActiveSupport::TestCase
  test "belongs_to donor returns the expected donor" do
    donation = donations(:defaults_only)
    assert_equal donors(:jane_smith), donation.donor
  end

  test "requires donor" do
    donation = Donation.new(amount: 10)
    assert_not donation.valid?
    assert_includes donation.errors[:donor], "must exist"
  end

  test "defaults amount and eligible_amount to zero when only donor is supplied" do
    donation = Donation.create!(donor: donors(:jane_smith))
    assert_equal 0, donation.amount
    assert_equal 0, donation.eligible_amount
  end

  test "defaults all four receipt_* booleans to false" do
    donation = Donation.create!(donor: donors(:jane_smith))
    assert_equal false, donation.receipt_required
    assert_equal false, donation.receipt_pending
    assert_equal false, donation.receipt_processed
    assert_equal false, donation.receipt_replaced
  end

  test "accepts arbitrary source_id, payment_id, publication_id (no FK constraints)" do
    donation = Donation.create!(
      donor: donors(:jane_smith),
      source_id: 9999,
      payment_id: 9999,
      publication_id: 9999
    )
    assert_equal 9999, donation.source_id
    assert_equal 9999, donation.payment_id
    assert_equal 9999, donation.publication_id
  end

  test "FK violation raises on bogus donor_id" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      Donation.connection.execute(
        "INSERT INTO donations (donor_id, created_at, updated_at) " \
        "VALUES (9999, NOW(), NOW())"
      )
    end
  end
end
