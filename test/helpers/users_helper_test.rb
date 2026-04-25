require "test_helper"

class UsersHelperTest < ActionView::TestCase
  include Turbo::FramesHelper

  # ActionView::TestCase includes ActionView::Helpers, ActionView::Context, etc.
  # Helper modules under test are included automatically via `helper_class`;
  # Turbo Rails helpers are NOT auto-included so we pull in FramesHelper for the
  # active-user avatar branch which calls turbo_frame_tag.

  # Build minimal User-like objects using actual AR fixtures to avoid complex stubs.

  setup do
    @active_user = users(:regular_user) # active, no deactivation record
    @deactivated_user = users(:deactivated_user) # has a deactivation record
    @admin_viewer = users(:admin_user)        # has system admin role → admin? == true
    @regular_viewer = users(:regular_user)    # no admin role → admin? == false
  end

  # ---------------------------------------------------------------------------
  # display_user_name
  # ---------------------------------------------------------------------------

  test "display_user_name: admin viewer sees raw name for active user" do
    result = display_user_name(@active_user, viewer: @admin_viewer)
    assert_equal @active_user.user_name, result
  end

  test "display_user_name: admin viewer sees raw name for deactivated user" do
    result = display_user_name(@deactivated_user, viewer: @admin_viewer)
    assert_equal @deactivated_user.user_name, result
  end

  test "display_user_name: non-admin viewer sees raw name for active user" do
    result = display_user_name(@active_user, viewer: @regular_viewer)
    assert_equal @active_user.user_name, result
  end

  test "display_user_name: non-admin viewer sees masked name for deactivated user" do
    result = display_user_name(@deactivated_user, viewer: @regular_viewer)
    raw = @deactivated_user.user_name
    expected = "#{raw[0..1]}**"
    assert_equal expected, result
  end

  test "display_user_name: masking uses first 2 chars of user_name" do
    # Confirm the mask format is exactly `first_two_chars + "**"`
    result = display_user_name(@deactivated_user, viewer: @regular_viewer)
    assert result.end_with?("**"), "Expected result to end with '**', got: #{result.inspect}"
    assert_equal 4, result.length, "Mask should be 2 chars + '**' == 4 chars (user_name starts with 'De')"
  end

  test "display_user_name: nil viewer treated as non-admin (shows mask for deactivated)" do
    result = display_user_name(@deactivated_user, viewer: nil)
    raw = @deactivated_user.user_name
    expected = "#{raw[0..1]}**"
    assert_equal expected, result
  end

  # ---------------------------------------------------------------------------
  # display_user_avatar
  # ---------------------------------------------------------------------------

  test "display_user_avatar: returns person_off markup for deactivated user" do
    result = display_user_avatar(@deactivated_user, viewer: @regular_viewer)
    assert_includes result, "person_off", "Expected person_off icon in deactivated avatar"
    assert_includes result, "user-avatar--deactivated", "Expected deactivated CSS class"
  end

  test "display_user_avatar: deactivated avatar is the same regardless of viewer role" do
    result_admin = display_user_avatar(@deactivated_user, viewer: @admin_viewer)
    result_regular = display_user_avatar(@deactivated_user, viewer: @regular_viewer)
    # Both should render person_off markup (identity redacted visually)
    assert_includes result_admin, "person_off"
    assert_includes result_regular, "person_off"
  end

  test "display_user_avatar: active user without avatar renders initial span" do
    # regular_user has no avatar attached in test fixtures
    result = display_user_avatar(@active_user, viewer: @regular_viewer)
    # Should render a turbo_frame wrapping an initial-sign span (existing user_icon behavior)
    assert_includes result, "user-avatar"
    assert_not_includes result, "person_off"
  end

  # ---------------------------------------------------------------------------
  # deactivation_status_badge
  # ---------------------------------------------------------------------------

  test "deactivation_status_badge: returns nil for active user" do
    result = deactivation_status_badge(@active_user)
    assert_nil result
  end

  test "deactivation_status_badge: returns badge markup for deactivated user" do
    result = deactivation_status_badge(@deactivated_user)
    assert_not_nil result
    assert_includes result, "person_off", "Expected person_off icon in badge"
    assert_includes result, "deactivation-badge", "Expected deactivation-badge CSS class"
  end
end
