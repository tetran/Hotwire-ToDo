require "test_helper"

class TaskSeriesTest < ActiveSupport::TestCase
  setup do
    @project = projects(:two)
    @user = users(:regular_user)
    @series = task_series(:weekly_mwf)
  end

  # === Validations ===

  test "requires name" do
    series = TaskSeries.new(project: @project, created_by: @user, frequency: :daily, interval: 1, end_mode: :infinite)
    assert_not series.valid?
    assert series.errors[:name].any?
  end

  test "interval must be >= 1" do
    series = TaskSeries.new(project: @project, created_by: @user, name: "x", frequency: :daily, interval: 0,
                            end_mode: :infinite)
    assert_not series.valid?
    assert series.errors[:interval].any?
  end

  test "count required when end_mode=count" do
    series = TaskSeries.new(project: @project, created_by: @user, name: "x", frequency: :daily, interval: 1,
                            end_mode: :count)
    assert_not series.valid?
    assert series.errors[:count].any?
  end

  test "until_date required when end_mode=until" do
    series = TaskSeries.new(project: @project, created_by: @user, name: "x", frequency: :daily, interval: 1,
                            end_mode: :until)
    assert_not series.valid?
    assert series.errors[:until_date].any?
  end

  test "by_weekday only allowed for weekly frequency" do
    series = TaskSeries.new(project: @project, created_by: @user, name: "x", frequency: :daily, interval: 1,
                            end_mode: :infinite, by_weekday: "mo")
    assert_not series.valid?
    assert series.errors[:by_weekday].any?
  end

  test "by_weekday rejects invalid codes" do
    series = TaskSeries.new(project: @project, created_by: @user, name: "x", frequency: :weekly, interval: 1,
                            end_mode: :infinite, by_weekday: "xx,mo")
    assert_not series.valid?
    assert series.errors[:by_weekday].any?
  end

  # === next_due_date_after: daily/weekly/monthly/yearly × interval ===

  test "next_due_date_after daily interval=1" do
    series = build_series(frequency: :daily, interval: 1)
    assert_equal Date.new(2026, 4, 7), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after daily interval=3" do
    series = build_series(frequency: :daily, interval: 3)
    assert_equal Date.new(2026, 4, 9), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after weekly interval=1 with no BYDAY" do
    series = build_series(frequency: :weekly, interval: 1)
    assert_equal Date.new(2026, 4, 13), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after weekly interval=2" do
    series = build_series(frequency: :weekly, interval: 2)
    assert_equal Date.new(2026, 4, 20), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after weekly with BYDAY selects next matching weekday" do
    # Monday 2026-04-06, with MWF → next is Wednesday 2026-04-08
    series = build_series(frequency: :weekly, interval: 1, by_weekday: "mo,we,fr")
    assert_equal Date.new(2026, 4, 8), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after monthly" do
    series = build_series(frequency: :monthly, interval: 1)
    assert_equal Date.new(2026, 5, 6), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after yearly" do
    series = build_series(frequency: :yearly, interval: 1)
    assert_equal Date.new(2027, 4, 6), series.next_due_date_after(Date.new(2026, 4, 6))
  end

  test "next_due_date_after returns nil when date is nil" do
    series = build_series(frequency: :daily, interval: 1)
    assert_nil series.next_due_date_after(nil)
  end

  # === terminated? ===

  test "terminated? when stopped_at set" do
    series = build_series(frequency: :daily, interval: 1)
    series.stopped_at = Time.current
    assert series.terminated?
  end

  test "terminated? when count exhausted" do
    series = build_series(frequency: :daily, interval: 1, end_mode: :count, count: 3)
    series.occurrences_generated = 3
    assert series.terminated?
  end

  test "not terminated? when count not yet exhausted" do
    series = build_series(frequency: :daily, interval: 1, end_mode: :count, count: 3)
    series.occurrences_generated = 2
    assert_not series.terminated?
  end

  test "terminated? when until date passed" do
    series = build_series(frequency: :daily, interval: 1, end_mode: :until, until_date: Date.current - 1)
    assert series.terminated?
  end

  test "not terminated? when until date not yet passed" do
    series = build_series(frequency: :daily, interval: 1, end_mode: :until, until_date: Date.current + 7)
    assert_not series.terminated?
  end

  # === configured? ===

  test "configured? when stopped_at is nil" do
    series = build_series(frequency: :daily, interval: 1)
    assert series.configured?
  end

  test "not configured? when stopped_at is set" do
    series = build_series(frequency: :daily, interval: 1)
    series.stopped_at = Time.current
    assert_not series.configured?
  end

  # === stop! ===

  test "stop! sets stopped_at" do
    series = create_series!
    assert_nil series.stopped_at
    series.stop!
    assert_not_nil series.reload.stopped_at
    assert series.terminated?
  end

  # === rrule derivation parity ===

  test "before_save derives rrule from structured fields (daily interval=2)" do
    series = create_series!(frequency: :daily, interval: 2)
    assert_equal "FREQ=DAILY;INTERVAL=2", series.rrule
  end

  test "before_save derives rrule (weekly MWF infinite)" do
    series = create_series!(frequency: :weekly, interval: 1, by_weekday: "mo,we,fr")
    assert_equal "FREQ=WEEKLY;BYDAY=MO,WE,FR", series.rrule
  end

  test "before_save derives rrule (monthly count=5)" do
    series = create_series!(frequency: :monthly, interval: 1, end_mode: :count, count: 5)
    assert_equal "FREQ=MONTHLY;COUNT=5", series.rrule
  end

  test "before_save derives rrule (yearly until)" do
    series = create_series!(frequency: :yearly, interval: 1, end_mode: :until, until_date: Date.new(2028, 1, 1))
    assert_match(/\AFREQ=YEARLY;UNTIL=20280101T/, series.rrule)
  end

  # === generate_next_instance! ===

  test "generate_next_instance! creates a new pending task with next due_date" do
    series = create_series!(frequency: :daily, interval: 1)
    seed = Task.create!(name: "seed", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    new_task = series.generate_next_instance!(from_task: seed)
    assert new_task.persisted?
    assert_equal Date.new(2026, 4, 7), new_task.due_date
    assert_equal series.id, new_task.task_series_id
    assert_equal 1, series.reload.occurrences_generated
  end

  test "generate_next_instance! copies series_subtasks as subtasks of new task" do
    series = task_series(:weekly_mwf)
    series.tasks.destroy_all
    seed = Task.create!(name: "x", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    new_task = series.generate_next_instance!(from_task: seed)
    subtask_names = new_task.subtasks.order(:created_at).pluck(:name)
    assert_includes subtask_names, "前回の振り返り"
    assert_includes subtask_names, "今週のアップデート"
  end

  test "generate_next_instance! does not copy comments" do
    series = create_series!(frequency: :daily, interval: 1)
    seed = Task.create!(name: "seed", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    Comment.create!(task: seed, user: @user, content: "hi")
    new_task = series.generate_next_instance!(from_task: seed)
    assert_equal 0, new_task.comments.count
  end

  test "generate_next_instance! increments occurrences_generated" do
    series = create_series!(frequency: :daily, interval: 1)
    seed = Task.create!(name: "seed", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    assert_equal 0, series.occurrences_generated
    series.generate_next_instance!(from_task: seed)
    assert_equal 1, series.reload.occurrences_generated
  end

  test "generate_next_instance! is no-op when an uncompleted sibling exists" do
    series = create_series!(frequency: :daily, interval: 1)
    seed = Task.create!(name: "seed", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    Task.create!(name: "already pending", project: @project, created_by: @user, due_date: Date.new(2026, 4, 7),
                 completed: false, task_series: series)
    result = series.generate_next_instance!(from_task: seed)
    assert_nil result
    assert_equal 0, series.reload.occurrences_generated
  end

  test "generate_next_instance! uses from_task.due_date as anchor (supports past-due rollover)" do
    series = create_series!(frequency: :weekly, interval: 1, by_weekday: "mo,we,fr")
    past_seed = Task.create!(name: "old", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                             completed: true, task_series: series)
    new_task = series.generate_next_instance!(from_task: past_seed)
    # Monday 2026-04-06 → next should be Wednesday 2026-04-08
    assert_equal Date.new(2026, 4, 8), new_task.due_date
  end

  test "generate_next_instance! returns nil when terminated" do
    series = create_series!(frequency: :daily, interval: 1)
    series.update!(stopped_at: Time.current)
    seed = Task.create!(name: "seed", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    assert_nil series.generate_next_instance!(from_task: seed)
  end

  test "generate_next_instance! returns nil when next date exceeds until_date" do
    series = create_series!(frequency: :daily, interval: 1, end_mode: :until, until_date: Date.new(2026, 4, 6))
    seed = Task.create!(name: "seed", project: @project, created_by: @user, due_date: Date.new(2026, 4, 6),
                        completed: true, task_series: series)
    assert_nil series.generate_next_instance!(from_task: seed)
  end

  # === sync_from_task! / propagate_to_pending! ===

  test "sync_from_task! applies name/assignee/description to series template" do
    series = create_series!(frequency: :daily, interval: 1)
    series.description = "original"
    series.save!
    other_user = users(:admin_user)
    task = Task.create!(name: "updated name", project: @project, created_by: @user, due_date: Date.current,
                        task_series: series, assignee: other_user)
    task.description = "new body"
    task.save!
    series.sync_from_task!(task)
    assert_equal "updated name", series.reload.name
    assert_equal other_user.id, series.assignee_id
    assert_includes series.description.to_s, "new body"
  end

  test "sync_from_task! clears description when task description is blank" do
    series = create_series!(frequency: :daily, interval: 1)
    series.description = "old"
    series.save!
    task = Task.create!(name: "n", project: @project, created_by: @user, due_date: Date.current,
                        task_series: series)
    task.description = ""
    task.save!
    series.sync_from_task!(task)
    assert series.reload.description.to_plain_text.strip.blank?,
           "expected series description to be cleared, got: #{series.description.to_plain_text.inspect}"
  end

  test "propagate_to_pending! clears sibling description when series description is blank" do
    series = create_series!(frequency: :daily, interval: 1)
    pending = Task.create!(name: "n", project: @project, created_by: @user, due_date: Date.current,
                           task_series: series)
    pending.description = "old"
    pending.save!
    # Series description left blank
    edited = Task.new(id: -1)
    series.propagate_to_pending!(except: edited)
    assert pending.reload.description.to_plain_text.strip.blank?,
           "expected sibling description to be cleared, got: #{pending.description.to_plain_text.inspect}"
  end

  test "propagate_to_pending! updates sibling pending tasks" do
    # Typical scope: there's 0-1 pending sibling because of the partial unique index.
    # Exercise the common case: one pending task that is NOT the edited one.
    series = create_series!(frequency: :daily, interval: 1)
    pending = Task.create!(name: "old name", project: @project, created_by: @user,
                           due_date: Date.current, task_series: series)
    series.update!(name: "new template name")
    edited = Task.new(id: -1) # sentinel: not the pending sibling
    series.propagate_to_pending!(except: edited)
    assert_equal "new template name", pending.reload.name
  end

  test "propagate_to_pending! skips the edited task itself" do
    series = create_series!(frequency: :daily, interval: 1)
    series.update!(name: "template")
    edited = Task.create!(name: "keep as-is for test", project: @project, created_by: @user, due_date: Date.current,
                          task_series: series)
    series.propagate_to_pending!(except: edited)
    # edited is the only pending, so it should not be updated
    assert_equal "keep as-is for test", edited.reload.name
  end

  private

    def build_series(**attrs)
      defaults = { project: @project, created_by: @user, name: "s", frequency: :daily, interval: 1,
                   end_mode: :infinite, occurrences_generated: 0 }
      TaskSeries.new(defaults.merge(attrs))
    end

    def create_series!(**attrs)
      build_series(**attrs).tap(&:save!)
    end
end
