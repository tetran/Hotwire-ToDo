require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "sign up and logout" do
    email = "newuser@example.com"
    password = "password123"

    visit signup_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Sign up"

    assert_selector ".project-name", text: "Inbox"
    assert_button "Add Task"

    submit_logout
    assert_current_path login_path
  end

  test "login and logout" do
    user = users(:regular_user)

    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Login"
    assert_current_path project_path(user.inbox_project)

    submit_logout
    assert_current_path login_path
  end

  private

  def submit_logout
    page.execute_script("document.querySelector('form[action=\"#{logout_path}\"]').submit()")
  end
end

