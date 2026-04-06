require "application_system_test_case"

class RecurringTasksTest < ApplicationSystemTestCase
  def setup
    @user = users(:regular_user)
  end

  test "create a weekly recurring task and see the badge" do
    sign_in_as(@user)
    open_project_menu
    click_link "Test Project Two"

    click_button I18n.t("tasks.add_task_btn.add_task")
    task_name = "週次スタンドアップ"
    within("turbo-frame#new_task") do
      fill_in I18n.t("tasks.form.task_name"), with: task_name

      # Pick a frequency (selecting any non-"none" value enables recurrence
      # and reveals the detail fields).
      select I18n.t("task_series.frequencies.weekly"),
             from: "task_recurrence_frequency"

      # Choose weekly mo/we/fr.
      check "task_recurrence_by_weekday_mo"
      check "task_recurrence_by_weekday_we"
      check "task_recurrence_by_weekday_fr"

      find(".task-form__submit").click
    end

    assert_selector ".task-card__name", text: task_name

    task = Task.find_by!(name: task_name)
    assert task.recurring?, "newly created task should be linked to a series"
    assert_equal "mo,we,fr", task.task_series.by_weekday

    badge = find("turbo-frame#task_#{task.id} .task-card__recurrence")
    assert_includes badge["title"], "毎週"
    assert_includes badge["title"], "月"
    assert_includes badge["title"], "水"
    assert_includes badge["title"], "金"
  end

  test "completing a recurring task generates the next instance via broadcast (no duplicate card)" do
    task = tasks(:recurring_weekly)
    sign_in_as(@user)
    open_project_menu
    click_link "Test Project Two"

    assert_selector "turbo-frame#task_#{task.id}"

    within("turbo-frame#task_#{task.id}") do
      find(".task-card__complete-check").click
    end

    assert_no_selector "turbo-frame#task_#{task.id}"

    # Exactly one card with the original name must remain (the generated next
    # instance), delivered via Task#broadcast_task_create. If the controller
    # view still did an explicit turbo_stream.append, we would see two.
    assert_selector ".task-card__name a", text: task.name, count: 1

    next_task = task.task_series.tasks.uncompleted.where.not(id: task.id).first
    assert_not_nil next_task
    assert_equal task.name, next_task.name
  end

  test "editing only the name does not change the series template" do
    task = tasks(:recurring_weekly)
    original_series_name = task.task_series.name
    sign_in_as(@user)
    assert_selector ".project-selector"
    visit edit_task_path(task)

    new_name = "週次MTG（更新）"
    fill_in "task[name]", with: new_name
    find(".task-form__submit").click

    # After submit, the edit form is gone (update.turbo_stream clears it).
    using_wait_time(5) do
      assert_no_selector ".task-form__submit"
    end

    # Changing just name does NOT touch template fields → no scope dialog,
    # submission uses default scope=only_this → series name unchanged.
    task.reload
    assert_equal new_name, task.name
    assert_equal original_series_name, task.task_series.reload.name
  end

  test "editing frequency via scope dialog all_future updates series template" do
    task = tasks(:recurring_weekly)
    series = task.task_series
    sign_in_as(@user)
    assert_selector ".project-selector"
    visit edit_task_path(task)

    # The recurrence <details> is open by default for recurring tasks.
    select I18n.t("task_series.frequencies.daily"),
           from: "task_recurrence_frequency"

    find(".task-form__submit").click

    # Scope dialog should appear; choose 今後すべて
    assert_selector "dialog.task-form__scope-dialog[open]"
    within("dialog.task-form__scope-dialog") do
      click_button I18n.t("tasks.form.recurrence.scope_dialog.all_future")
    end

    # Wait for the submit round-trip.
    using_wait_time(5) do
      assert_no_selector ".task-form__submit"
    end

    series.reload
    assert_equal "daily", series.frequency
    assert_nil series.by_weekday, "stale weekly by_weekday must be cleared"
  end

  test "stopping recurrence clears the badge and prevents further generation" do
    task = tasks(:recurring_weekly)
    sign_in_as(@user)
    assert_selector ".project-selector"
    visit edit_task_path(task)

    # Click Stop and accept the turbo-confirm dialog.
    accept_confirm do
      click_link I18n.t("tasks.form.recurrence.stop")
    end

    # Wait for the notification stream to confirm DELETE completed.
    assert_selector "#notification", text: I18n.t("controllers.tasks/recurrences.destroy.success")

    # Series is stopped in DB.
    assert_not_nil task.task_series.reload.stopped_at

    # Re-opening the edit form shows recurrence as "none" with no stop button.
    visit edit_task_path(task)
    assert_equal "none", find("#task_recurrence_frequency").value
    assert_no_link I18n.t("tasks.form.recurrence.stop")

    # Navigate back to project page and verify badge is gone.
    visit project_path(task.project)
    assert_selector "turbo-frame#task_#{task.id}"
    within("turbo-frame#task_#{task.id}") do
      assert_no_selector ".task-card__recurrence"
    end

    # Completing the task now does NOT generate a next instance.
    within("turbo-frame#task_#{task.id}") do
      find(".task-card__complete-check").click
    end
    assert_no_selector "turbo-frame#task_#{task.id}"
    assert_equal 0, task.task_series.reload.tasks.uncompleted.count
  end

  test "setting recurrence again after stopping creates a new active series" do
    task = tasks(:recurring_weekly)
    original_series_id = task.task_series_id
    task.task_series.stop!

    sign_in_as(@user)
    assert_selector ".project-selector"
    visit edit_task_path(task)

    # Old stopped series is treated as absent; form shows "繰り返さない".
    assert_equal "none", find("#task_recurrence_frequency").value

    # User picks a new frequency and submits.
    select I18n.t("task_series.frequencies.daily"), from: "task_recurrence_frequency"
    find(".task-form__submit").click

    using_wait_time(5) do
      assert_no_selector ".task-form__submit"
    end

    task.reload
    assert_not_nil task.task_series, "task must be attached to a series"
    assert_not_equal original_series_id, task.task_series_id, "a new series should be created"
    assert_equal "daily", task.task_series.frequency
    assert_nil task.task_series.stopped_at
  end
end
