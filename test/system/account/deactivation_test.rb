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

    # Regression: the user settings modal (`users#show` inside `<turbo-frame id="modal">`)
    # contains the deactivation link. Without `data-turbo-frame="_top"` on the link, Turbo
    # tries to find a matching `modal` frame in the response and renders "Content missing"
    # because `account/deactivations/new` is a full-page view. Cancelling from the full-page
    # deactivation view must also land on a real page (root_path), not a stranded modal frame.
    test "self-deactivation link inside user settings modal navigates full-page (not 'Content missing')" do
      user = users(:regular_user)

      visit login_path
      fill_in I18n.t("activerecord.attributes.user.email"), with: user.email
      fill_in I18n.t("activerecord.attributes.user.password"), with: "HoboTest!Str0ng#2024"
      click_button I18n.t("sessions.new.submit")
      assert_current_path project_path(user.inbox_project)

      visit user_path
      click_link I18n.t("users.user_display.deactivate")

      assert_current_path new_account_deactivation_path
      assert_no_text "Content missing"
      assert_selector "h1", text: I18n.t("account.deactivations.new.title")

      click_link I18n.t("account.deactivations.new.cancel")
      assert_current_path root_path
    end
  end
end
