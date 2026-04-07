require "test_helper"

module Tasks
  class InlineFieldsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @task = tasks(:two)
    end

    # --- Authentication ---

    test "edit requires login" do
      get edit_task_inline_field_url(@task, "name")
      assert_redirected_to login_url
    end

    test "update requires login" do
      patch task_inline_field_url(@task, "name"),
            params: { task: { name: "New Name" } }
      assert_redirected_to login_url
    end

    # --- Authorization ---

    test "edit returns not found for non-member user's task" do
      login_as(users(:no_role_user))
      get edit_task_inline_field_url(@task, "name")
      assert_response :not_found
    end

    test "update returns not found for non-member user's task" do
      login_as(users(:no_role_user))
      patch task_inline_field_url(@task, "name"),
            params: { task: { name: "Hacked" } }
      assert_response :not_found
    end

    # --- Invalid field name ---

    test "edit returns not found for invalid field" do
      login_as_regular_user
      get edit_task_inline_field_url(@task, "completed")
      assert_response :not_found
    end

    test "update returns not found for invalid field" do
      login_as_regular_user
      patch task_inline_field_url(@task, "completed"),
            params: { task: { completed: true } }
      assert_response :not_found
    end

    # --- Edit ---

    test "edit name renders form" do
      login_as_regular_user
      get edit_task_inline_field_url(@task, "name")
      assert_response :success
    end

    test "edit description renders form" do
      login_as_regular_user
      get edit_task_inline_field_url(@task, "description")
      assert_response :success
    end

    test "edit due_date renders form" do
      login_as_regular_user
      get edit_task_inline_field_url(@task, "due_date")
      assert_response :success
    end

    # --- Update (success) ---

    test "update name via turbo_stream" do
      login_as_regular_user
      patch task_inline_field_url(@task, "name"),
            params: { task: { name: "Updated Name" } },
            as: :turbo_stream
      assert_response :success
      assert_equal "Updated Name", @task.reload.name
    end

    test "update description via turbo_stream" do
      login_as_regular_user
      patch task_inline_field_url(@task, "description"),
            params: { task: { description: "New description" } },
            as: :turbo_stream
      assert_response :success
      assert_equal "New description",
                   @task.reload.description.to_plain_text.strip
    end

    test "update due_date via turbo_stream" do
      login_as_regular_user
      new_date = Date.new(2025, 6, 15)
      patch task_inline_field_url(@task, "due_date"),
            params: { task: { due_date: new_date } },
            as: :turbo_stream
      assert_response :success
      assert_equal new_date, @task.reload.due_date
    end

    # --- Update (validation error) ---

    test "update with blank name returns unprocessable content" do
      login_as_regular_user
      patch task_inline_field_url(@task, "name"),
            params: { task: { name: "" } },
            as: :turbo_stream
      assert_response :unprocessable_content
      assert_not_equal "", @task.reload.name
    end

    test "update with too long name returns unprocessable content" do
      login_as_regular_user
      patch task_inline_field_url(@task, "name"),
            params: { task: { name: "a" * 101 } },
            as: :turbo_stream
      assert_response :unprocessable_content
    end

    # --- Only permits the requested field ---

    test "update only permits the specified field" do
      login_as_regular_user
      original_name = @task.name
      patch task_inline_field_url(@task, "due_date"),
            params: {
              task: { due_date: Date.new(2025, 7, 1), name: "Sneaky" },
            },
            as: :turbo_stream
      assert_response :success
      assert_equal original_name, @task.reload.name
      assert_equal Date.new(2025, 7, 1), @task.due_date
    end
  end
end
