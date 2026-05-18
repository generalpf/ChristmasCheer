require "test_helper"

class DonorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @donor = donors(:jane_smith)
  end

  # ---- auth ----

  test "GET /donors unauthenticated redirects to sign-in" do
    get donors_path
    assert_redirected_to new_session_path
  end

  # ---- index ----

  test "GET /donors authenticated returns 200 with a known donor and link" do
    sign_in_as(@user)
    get donors_path
    assert_response :success
    assert_match "Smith", response.body
    assert_select "a[href=?]", donor_path(@donor)
  end

  test "GET /donors?q=substring filters by last_name case-insensitively" do
    sign_in_as(@user)
    get donors_path, params: { q: "smit" }
    assert_response :success
    assert_match "Smith", response.body
    assert_no_match(/Doe/, response.body)
  end

  test "GET /donors?q=substring filters by company case-insensitively" do
    sign_in_as(@user)
    get donors_path, params: { q: "acme" }
    assert_response :success
    assert_match "Acme Widgets Ltd.", response.body
    assert_no_match(/Smith/, response.body)
  end

  test "GET /donors?q= empty returns full list" do
    sign_in_as(@user)
    get donors_path, params: { q: "" }
    assert_response :success
    assert_match "Smith", response.body
    assert_match "Acme Widgets Ltd.", response.body
  end

  test "GET /donors paginates at 50 per page" do
    44.times do |i|
      Donor.create!(
        affiliate: affiliates(:brandon_cc),
        category: categories(:business),
        courtesy_title: courtesy_titles(:to_whom),
        company: format("BulkCo %03d", i)
      )
    end
    assert Donor.count > 50

    sign_in_as(@user)
    get donors_path, params: { page: 1 }
    assert_response :success
    page1_rows = css_select("table.donors-list tbody tr").length
    assert_operator page1_rows, :<=, 50
    assert_select "a[href=?]", donors_path(page: 2)
  end

  # ---- show ----

  test "GET /donors/:id renders all fields and association names" do
    sign_in_as(@user)
    get donor_path(@donor)
    assert_response :success
    assert_match "Jane", response.body
    assert_match "Smith", response.body
    assert_match "BrandonCC", response.body
    assert_match "Individual", response.body
    assert_match "Ms.", response.body
    assert_select "a[href=?]", edit_donor_path(@donor)
    assert_select "form[action=?][method=?]", donor_path(@donor), "post" do
      assert_select "input[name=_method][value=delete]", count: 1
    end
  end

  test "GET /donors/:id handles nil city_town" do
    sign_in_as(@user)
    donor = donors(:john_no_city)
    assert_nil donor.city_town
    get donor_path(donor)
    assert_response :success
    assert_match "Doe", response.body
  end

  test "GET /donors/:id renders zip_code text but no zip_code input" do
    @donor.update_columns(zip_code: "55101")
    sign_in_as(@user)
    get donor_path(@donor)
    assert_response :success
    assert_match "55101", response.body
    assert_no_match(/name=.donor\[zip_code\]/, response.body)
  end

  # ---- new ----

  test "GET /donors/new renders form with reference dropdowns and no zip_code" do
    sign_in_as(@user)
    get new_donor_path
    assert_response :success

    assert_select "select[name=?]", "donor[affiliate_id]" do
      assert_select "option", count: Affiliate.count
    end
    assert_select "select[name=?]", "donor[category_id]" do
      assert_select "option", count: Category.count
    end
    assert_select "select[name=?]", "donor[courtesy_title_id]" do
      assert_select "option", count: CourtesyTitle.count
    end
    assert_select "select[name=?]", "donor[city_town_id]" do
      assert_select "option[value='']", count: 1
    end
    assert_no_match(/name=.donor\[zip_code\]/, response.body)
  end

  # ---- create ----

  test "POST /donors with valid params persists and redirects to show" do
    sign_in_as(@user)
    assert_difference -> { Donor.count }, 1 do
      post donors_path, params: { donor: {
        affiliate_id: affiliates(:brandon_cc).id,
        category_id: categories(:individual).id,
        courtesy_title_id: courtesy_titles(:mr).id,
        first_name: "Pat",
        last_name: "Lee"
      } }
    end
    new_donor = Donor.order(:id).last
    assert_redirected_to donor_path(new_donor)
    assert_equal "Pat", new_donor.first_name
    assert_equal "Lee", new_donor.last_name
  end

  test "POST /donors with only first name returns 422 and renders :base error" do
    sign_in_as(@user)
    assert_no_difference -> { Donor.count } do
      post donors_path, params: { donor: {
        affiliate_id: affiliates(:brandon_cc).id,
        category_id: categories(:individual).id,
        courtesy_title_id: courtesy_titles(:mr).id,
        first_name: "Pat"
      } }
    end
    assert_response :unprocessable_entity
    assert_match "must have both a first and last name, or a company", response.body
  end

  # ---- edit ----

  test "GET /donors/:id/edit pre-fills inputs and marks reference options selected" do
    sign_in_as(@user)
    get edit_donor_path(@donor)
    assert_response :success
    assert_select "input[name=?][value=?]", "donor[first_name]", "Jane"
    assert_select "select[name=?]", "donor[category_id]" do
      assert_select "option[selected=selected][value=?]", @donor.category_id.to_s
    end
  end

  # ---- update ----

  test "PATCH /donors/:id with valid changes persists and redirects to show" do
    sign_in_as(@user)
    patch donor_path(@donor), params: { donor: { last_name: "Leigh" } }
    assert_redirected_to donor_path(@donor)
    assert_equal "Leigh", @donor.reload.last_name
  end

  test "PATCH /donors/:id blanking last name on individual returns 422 without modifying" do
    sign_in_as(@user)
    original_last_name = @donor.last_name
    patch donor_path(@donor), params: { donor: { last_name: "" } }
    assert_response :unprocessable_entity
    assert_match "must have both a first and last name, or a company", response.body
    assert_equal original_last_name, @donor.reload.last_name
  end

  # ---- destroy ----

  test "DELETE /donors/:id removes the donor and redirects with success flash" do
    sign_in_as(@user)
    target = Donor.create!(
      affiliate: affiliates(:brandon_cc),
      category: categories(:business),
      courtesy_title: courtesy_titles(:to_whom),
      company: "Doomed Co"
    )
    assert_difference -> { Donor.count }, -1 do
      delete donor_path(target)
    end
    assert_redirected_to donors_path
    assert_match(/deleted/i, flash[:notice].to_s)
  end

  test "DELETE /donors/:id with DeleteRestrictionError preserves donor and shows error flash" do
    sign_in_as(@user)

    fake = @donor
    fake.define_singleton_method(:destroy) do
      raise ActiveRecord::DeleteRestrictionError.new("donations")
    end
    Donor.singleton_class.alias_method(:_orig_find_for_test, :find)
    Donor.define_singleton_method(:find) { |_| fake }
    begin
      delete donor_path(@donor)
    ensure
      Donor.singleton_class.alias_method(:find, :_orig_find_for_test)
      Donor.singleton_class.send(:remove_method, :_orig_find_for_test)
    end

    assert_response :redirect
    assert_redirected_to donor_path(@donor)
    assert_match(/dependent records/i, flash[:alert].to_s)
    assert Donor.exists?(@donor.id), "donor should not have been deleted"
  end

  # ---- menu page link ----

  test "GET / contains link to /donors and no future: donors placeholder" do
    sign_in_as(@user)
    get root_path
    assert_response :success
    assert_select "a[href=?]", donors_path, text: "Donors"
    assert_no_match(/future: donors/, response.body)
  end
end
