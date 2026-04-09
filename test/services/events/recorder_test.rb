require "test_helper"

module Events
  class RecorderTest < ActiveSupport::TestCase
    setup do
      @user = users(:regular_user)
      @project = projects(:two)
      @task = tasks(:two)
    end

    test "records an event with all attributes" do
      assert_difference("Event.count", 1) do
        event = Events::Recorder.record(
          event_name: "task_created",
          user: @user,
          project: @project,
          task: @task,
          metadata: { changed_fields: %w[name] },
        )

        assert_equal "task_created", event.event_name
        assert_equal @user, event.user
        assert_equal @project, event.project
        assert_equal @task, event.task
        assert_equal "basic_operation", event.feature_category
        assert_not_nil event.occurred_at
        assert_equal({ "changed_fields" => %w[name] }, event.metadata)
      end
    end

    test "auto-derives feature_category from event_name" do
      event = Events::Recorder.record(event_name: "comment_posted", user: @user)
      assert_equal "collaboration", event.feature_category

      event = Events::Recorder.record(event_name: "due_date_set", user: @user)
      assert_equal "planning", event.feature_category

      event = Events::Recorder.record(event_name: "task_deleted", user: @user)
      assert_equal "basic_operation", event.feature_category
    end

    test "sets occurred_at automatically" do
      freeze_time do
        event = Events::Recorder.record(event_name: "task_created", user: @user)
        assert_equal Time.current, event.occurred_at
      end
    end

    test "project and task are optional" do
      assert_difference("Event.count", 1) do
        event = Events::Recorder.record(event_name: "project_created", user: @user)
        assert_nil event.project
        assert_nil event.task
      end
    end

    test "metadata defaults to empty hash" do
      event = Events::Recorder.record(event_name: "task_created", user: @user)
      assert_equal({}, event.metadata)
    end

    test "does not raise on recording failure and logs error" do
      assert_nothing_raised do
        event = Events::Recorder.record(event_name: "invalid_event", user: @user)
        assert_nil event
      end
    end

    test "does not create event on recording failure" do
      assert_no_difference("Event.count") do
        Events::Recorder.record(event_name: "invalid_event", user: @user)
      end
    end
  end
end
