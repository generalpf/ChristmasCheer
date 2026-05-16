require "test_helper"

class CityTownTest < ActiveSupport::TestCase
  test "model loads and table is queryable" do
    assert CityTown.table_exists?
    assert_equal %w[id name], CityTown.column_names.sort
  end

  test "has_many :donors returns donors with this city_town" do
    brandon = city_towns(:brandon)
    assert_includes brandon.donors, donors(:jane_smith)
    assert_includes brandon.donors, donors(:acme_business)
  end

  test "name is required at the database level" do
    assert_raises(ActiveRecord::NotNullViolation) do
      CityTown.connection.execute("INSERT INTO city_towns (name) VALUES (NULL)")
    end
  end
end
