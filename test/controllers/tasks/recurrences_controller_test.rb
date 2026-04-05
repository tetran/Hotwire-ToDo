require "test_helper"

module Tasks
  class RecurrencesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:regular_user)
      @task = tasks(:recurring_weekly)
      login_as(@user)
    end

    test "destroy stops the series and re-renders the task card" do
      assert_nil @task.task_series.stopped_at

      delete task_recurrence_path(@task), as: :turbo_stream
      assert_response :success

      assert_not_nil @task.task_series.reload.stopped_at
      assert_match 'action="replace"', response.body
      assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@task)}"), response.body
      assert_match 'target="notification"', response.body
    end

    test "after stop, completing task does not generate a next instance" do
      delete task_recurrence_path(@task), as: :turbo_stream
      assert_response :success

      before_count = Task.where(task_series_id: @task.task_series_id).count
      post task_complete_path(@task), as: :turbo_stream
      assert_response :success
      assert_equal before_count, Task.where(task_series_id: @task.task_series_id).count
    end

    test "non-member cannot access the task recurrence" do
      delete logout_path
      follow_redirect!
      login_as(users(:no_role_user))
      # Verify we're logged in as no_role_user
      assert_equal users(:no_role_user).id, session[:user_id]

      delete task_recurrence_path(@task), as: :turbo_stream
      assert_response :not_found
    end
  end
end
