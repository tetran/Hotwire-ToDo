require "application_system_test_case"

module Account
  class DeactivationTest < ApplicationSystemTestCase
    test "self-deactivation: form submission deactivates the account and blocks re-login" do
      user = users(:regular_user)
      original_email = user.email

      visit login_path
      fill_in I18n.t("activerecord.attributes.user.email"), with: original_email
      fill_in I18n.t("activerecord.attributes.user.password"), with: "HoboTest!Str0ng#2024"
      click_button I18n.t("sessions.new.submit")

      assert_current_path project_path(user.inbox_project)

      visit new_account_deactivation_path
      fill_in I18n.t("activerecord.attributes.user.password_challenge"), with: "HoboTest!Str0ng#2024"
      fill_in I18n.t("account.deactivations.new.reason_label"), with: "system test"
      check "confirm_deactivation"
      click_button I18n.t("account.deactivations.new.submit")

      assert_current_path login_path

      visit login_path
      fill_in I18n.t("activerecord.attributes.user.email"), with: original_email
      fill_in I18n.t("activerecord.attributes.user.password"), with: "HoboTest!Str0ng#2024"
      click_button I18n.t("sessions.new.submit")

      assert_current_path login_path
      assert user.reload.deactivated?
      assert_equal original_email, user.deactivation.original_email
    end
  end
end
