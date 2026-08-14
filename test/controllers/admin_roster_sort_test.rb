require "test_helper"

# The roster's order. Like the role chips and the search before it, the order is
# query-string state and a whitelist the console owns — and it is applied in SQL,
# because a sort that ran after paging would sort one page of an unsorted roster
# (ADR-0050).
class AdminRosterSortTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the roster orders by role and name unless asked otherwise" do
    get admin_url(tab: :users)

    assert_response :success
    assert_select "a[aria-current=true]", text: I18n.t("admin.sorts.role")
    assert_equal User.order(:role, :name).map(&:id), rendered_user_ids
  end

  test "each order in the whitelist is the order the roster comes back in" do
    AdminConsole::SORTS.each do |option, columns|
      get admin_url(tab: :users, sort: option)

      assert_response :success
      assert_equal User.order(*columns).map(&:id), rendered_user_ids, "sort=#{option}"
    end
  end

  test "an order nobody defined falls back to the default rather than to SQL" do
    get admin_url(tab: :users, sort: "created_at; DROP TABLE users")

    assert_response :success
    assert_equal User.order(:role, :name).map(&:id), rendered_user_ids
    assert_predicate User.count, :positive?
  end

  test "the order survives a filter, and the filter survives the order" do
    get admin_url(tab: :users, sort: :name, role: :instructor)

    assert_response :success
    assert_equal User.where(role: "instructor").order(:name).map(&:id), rendered_user_ids
    # Both chips keep the other's state in the links they offer.
    assert_select "a[href=?]", admin_path(tab: :users, role: :instructor, sort: :joined)
    assert_select "a[href=?]", admin_path(tab: :users, role: :admin, sort: :name)
  end

  test "the default order is spelled by leaving it out of the URL" do
    get admin_url(tab: :users, sort: :name)

    assert_response :success
    assert_select "a[href=?]", admin_path(tab: :users)
  end

  test "the search keeps the order it was run in" do
    get admin_url(tab: :users, sort: :name)

    assert_response :success
    assert_select "form input[name=sort][value=name]", 1 if FeatureSetting.enabled?(:search)
  end

  test "sorting is ordering, not filtering: the roster keeps every row" do
    AdminConsole::SORTS.each_key do |option|
      get admin_url(tab: :users, sort: option)

      assert_equal User.count, rendered_user_ids.size, "sort=#{option} dropped rows"
    end
  end

  test "both locales name every order" do
    %i[ en th ].each do |locale|
      AdminConsole::SORTS.each_key do |option|
        assert I18n.t("admin.sorts.#{option}", locale:, default: nil).present?,
               "#{locale} is missing admin.sorts.#{option}"
      end
      assert I18n.t("admin.sort_label", locale:, default: nil).present?
    end
  end

  private
    def rendered_user_ids
      css_select("[data-user-id]").map { it["data-user-id"].to_i }
    end
end
