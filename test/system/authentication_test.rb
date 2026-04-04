require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "sign up and logout" do
    email = "newuser@example.com"
    password = "HoboTest!Str0ng#2024"

    visit signup_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: email
    fill_in I18n.t("activerecord.attributes.user.password"), with: password
    click_button I18n.t("users.new.submit")

    assert_selector ".project-name", text: I18n.t("project.inbox")
    assert_button I18n.t("tasks.add_task_btn.add_task")

    submit_logout
    assert_current_path login_path
  end

  test "login and logout" do
    user = users(:regular_user)

    visit login_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: user.email
    fill_in I18n.t("activerecord.attributes.user.password"), with: "HoboTest!Str0ng#2024"
    click_button I18n.t("sessions.new.submit")
    assert_current_path project_path(user.inbox_project)

    submit_logout
    assert_current_path login_path
  end

  private

    def submit_logout
      page.execute_script("document.querySelector('form[action=\"#{logout_path}\"]').submit()")
    end
end
