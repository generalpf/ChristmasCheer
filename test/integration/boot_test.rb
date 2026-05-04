require "test_helper"

class BootTest < ActiveSupport::TestCase
  test "ActiveRecord is connected to PostgreSQL" do
    assert_equal "PostgreSQL", ActiveRecord::Base.connection.adapter_name
  end
end
