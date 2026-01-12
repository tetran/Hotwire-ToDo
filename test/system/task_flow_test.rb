require "application_system_test_case"

class TaskFlowTest < ApplicationSystemTestCase
  test "create, show, and complete a task in a project" do
    user = users(:regular_user)

    sign_in_as(user)
    open_project_menu
    click_link "Test Project Two"

    click_button "Add Task"
    task_name = "Write system tests"
    within("turbo-frame#new_task") do
      fill_in "Task name", with: task_name
      find(".task-form__submit").click
    end

    assert_selector ".task-card__name", text: task_name
    click_link task_name
    assert_selector "dialog.modal-base", text: task_name
    find("dialog.modal-base .modal-header__close").click
    assert_no_selector "dialog.modal-base[open]"

    task = Task.find_by!(name: task_name)
    within("turbo-frame#task_#{task.id}") do
      find(".task-card__complete-check").click
    end

    assert_no_selector "turbo-frame#task_#{task.id}"
  end

  private

    def sign_in_as(user)
      visit login_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "password"
      click_button "Login"
    end

    def open_project_menu
      find(".project-selector .menu-button").click
    end
end
