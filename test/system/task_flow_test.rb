require "application_system_test_case"

class TaskFlowTest < ApplicationSystemTestCase
  test "create, show, and complete a task in a project" do
    user = users(:regular_user)

    sign_in_as(user)
    open_project_menu
    click_link "Test Project Two"

    click_button I18n.t("tasks.add_task_btn.add_task")
    task_name = "Write system tests"
    within("turbo-frame#new_task") do
      fill_in I18n.t("tasks.form.task_name"), with: task_name
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

  test "create subtask, expand, and complete parent task" do
    user = users(:regular_user)
    parent = tasks(:parent_task)

    sign_in_as(user)
    open_project_menu
    click_link "Test Project Two"

    # Expand subtasks
    within("turbo-frame#task_#{parent.id}") do
      assert_selector ".task-card__subtask-badge", text: "1/2"
      find(".task-card__subtask-badge").click
      assert_selector ".task-card--subtask", count: 2
    end

    # Open parent task detail and add a subtask
    click_link parent.name
    assert_selector "dialog.modal-base", text: parent.name
    click_button I18n.t("tasks.show.add_subtask")
    fill_in I18n.t("tasks.form.task_name"), with: "New Subtask from System Test"
    find(".task-form__submit").click

    # Close modal
    find("dialog.modal-base .modal-header__close").click
    assert_no_selector "dialog.modal-base[open]"

    # Complete parent task — should cascade
    find("turbo-frame#task_#{parent.id} .task-card__complete-check", match: :first).click

    assert_no_selector "turbo-frame#task_#{parent.id}"

    # Verify cascade
    assert parent.reload.completed?
    assert parent.subtasks.all?(&:completed?)
  end
end
