require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @project = projects(:two)
    @task = tasks(:two)
  end

  # === Validations ===

  test "valid with all required attributes" do
    event = Event.new(
      event_name: "task_created",
      occurred_at: Time.current,
      user: @user,
      project: @project,
      task: @task,
      feature_category: "basic_operation",
    )
    assert event.valid?
  end

  test "invalid without event_name" do
    event = Event.new(occurred_at: Time.current, user: @user, feature_category: "basic_operation")
    assert_not event.valid?
    assert event.errors[:event_name].any?
  end

  test "invalid with unknown event_name" do
    event = Event.new(
      event_name: "unknown_event", occurred_at: Time.current, user: @user, feature_category: "basic_operation",
    )
    assert_not event.valid?
    assert event.errors[:event_name].any?
  end

  test "invalid without occurred_at" do
    event = Event.new(event_name: "task_created", user: @user, feature_category: "basic_operation")
    assert_not event.valid?
    assert event.errors[:occurred_at].any?
  end

  test "invalid without user" do
    event = Event.new(event_name: "task_created", occurred_at: Time.current, feature_category: "basic_operation")
    assert_not event.valid?
    assert event.errors[:user].any?
  end

  test "invalid without feature_category" do
    event = Event.new(event_name: "task_created", occurred_at: Time.current, user: @user)
    assert_not event.valid?
    assert event.errors[:feature_category].any?
  end

  test "valid without project and task" do
    event = Event.new(
      event_name: "project_created",
      occurred_at: Time.current,
      user: @user,
      feature_category: "basic_operation",
    )
    assert event.valid?
  end

  test "all EVENT_NAMES are valid" do
    Event::EVENT_NAMES.each do |name|
      event = Event.new(
        event_name: name,
        occurred_at: Time.current,
        user: @user,
        feature_category: "basic_operation",
      )
      assert event.valid?, "#{name} should be a valid event_name"
    end
  end

  # === Constants ===

  test "EVENT_NAMES contains exactly 8 event types" do
    assert_equal 8, Event::EVENT_NAMES.size
    assert_includes Event::EVENT_NAMES, "task_created"
    assert_includes Event::EVENT_NAMES, "task_completed"
    assert_includes Event::EVENT_NAMES, "task_updated"
    assert_includes Event::EVENT_NAMES, "task_deleted"
    assert_includes Event::EVENT_NAMES, "comment_posted"
    assert_includes Event::EVENT_NAMES, "project_created"
    assert_includes Event::EVENT_NAMES, "assignee_changed"
    assert_includes Event::EVENT_NAMES, "due_date_changed"
  end

  test "FEATURE_CATEGORIES maps every event name to a category" do
    Event::EVENT_NAMES.each do |name|
      assert Event::FEATURE_CATEGORIES.key?(name), "FEATURE_CATEGORIES should have a mapping for #{name}"
    end
  end

  # === Associations ===

  test "belongs to user" do
    event = events(:task_created_event)
    assert_instance_of User, event.user
  end

  test "belongs to project (optional)" do
    event = events(:task_created_event)
    assert_instance_of Project, event.project
  end

  test "belongs to task (optional)" do
    event = events(:task_created_event)
    assert_instance_of Task, event.task
  end

  # === Scopes ===

  test "by_user filters by user_id" do
    results = Event.by_user(@user.id)
    results.each do |event|
      assert_equal @user.id, event.user_id
    end
  end

  test "by_project filters by project_id" do
    results = Event.by_project(@project.id)
    results.each do |event|
      assert_equal @project.id, event.project_id
    end
  end

  test "by_event_name filters by event_name" do
    results = Event.by_event_name("task_created")
    results.each do |event|
      assert_equal "task_created", event.event_name
    end
  end

  test "recent orders by occurred_at desc" do
    results = Event.recent.to_a
    results.each_cons(2) do |a, b|
      assert a.occurred_at >= b.occurred_at
    end
  end
end
