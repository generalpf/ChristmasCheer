require "test_helper"

class ReferenceTablesTest < ActiveSupport::TestCase
  test "affiliates has 7 rows in Access order" do
    assert_equal 7, Affiliate.count
    assert_equal(
      %w[BoissevainCC BrandonCC DeloraineCC EOS_CC MelitaCC RiversCC VirdenCC],
      Affiliate.order(:id).pluck(:name)
    )
  end

  test "Affiliate.find(4) is EOS_CC" do
    assert_equal "EOS_CC", Affiliate.find(4).name
  end

  test "categories has 6 rows in Access order" do
    assert_equal 6, Category.count
    assert_equal(
      ["Business", "Government", "Group/Organization", "Individual",
       "Other (Specify in Notes)", "VOID Receipt"],
      Category.order(:id).pluck(:name)
    )
  end

  test "Category.find(4) is Individual" do
    assert_equal "Individual", Category.find(4).name
  end

  test "courtesy_titles has 11 rows in Access order" do
    assert_equal 11, CourtesyTitle.count
    assert_equal(
      ["Dr.", "Dr. & Mrs.", "Fr.", "Minister", "Miss", "Mr.", "Mr. & Mrs.",
       "Mrs.", "Ms.", "To Whom It May Concern", "None"],
      CourtesyTitle.order(:id).pluck(:title)
    )
  end

  test "CourtesyTitle.find(6) is Mr." do
    assert_equal "Mr.", CourtesyTitle.find(6).title
  end

  test "payments has 7 rows in Access order" do
    assert_equal 7, Payment.count
    assert_equal(
      ["Cash", "Cheque", "EFT", "Gift Card", "Gift in Kind",
       "Other (Specify in Notes)", "Square"],
      Payment.order(:id).pluck(:name)
    )
  end

  test "Payment.find(2) is Cheque" do
    assert_equal "Cheque", Payment.find(2).name
  end

  test "publications has 9 rows in Access order" do
    assert_equal 9, Publication.count
    assert_equal(
      ["Anonymous", "Business Name", "Canadian Tire Customers",
       "Fill the Bus-Safeway Customers", "Fill the Bus-Sobeys West Customers",
       "Name as Written", "None", "Other (Specify in Message)", "UCT Bingo Players"],
      Publication.order(:id).pluck(:name)
    )
  end

  test "Publication.find(3) is Canadian Tire Customers" do
    assert_equal "Canadian Tire Customers", Publication.find(3).name
  end

  test "sources has 16 rows in Access order" do
    assert_equal 16, Source.count
    assert_equal(
      ["DeloraineCC", "Benevity", "CanadaHelps", "Canadian Tire", "CC Office",
       "e-Transfer", "Fill the Bus", "Mail", "Other (Specify in Notes)", "PayPal",
       "UCT Bingo", "BoissevainCC", "MelitaCC", "RiversCC", "EOS_CC", "VirdenCC"],
      Source.order(:id).pluck(:name)
    )
  end

  test "Source.find(8) is Mail" do
    assert_equal "Mail", Source.find(8).name
  end
end
