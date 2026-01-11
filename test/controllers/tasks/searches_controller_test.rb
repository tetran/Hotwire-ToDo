require "test_helper"

module Tasks
  class SearchesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:regular_user)
      @task = tasks(:two)
    end

    test "should redirect to login when not authenticated" do
      get tasks_searches_path
      assert_redirected_to login_path
    end

    test "should get index without query" do
      login_as(@user)
      get tasks_searches_path
      assert_response :success
      assert_no_match(/search-result__name/, response.body)
    end

    test "should search tasks by name" do
      login_as(@user)
      get tasks_searches_path, params: { q: @task.name }
      assert_response :success
      assert_match(/search-result__name.*#{Regexp.escape(@task.name)}/m, response.body)
    end

    test "should not find tasks from non-participating projects" do
      login_as(users(:admin_user))
      get tasks_searches_path, params: { q: @task.name }
      assert_response :success
      assert_match(/0 results/, response.body)
    end

    test "should filter completed tasks" do
      @task.update!(completed: true)
      login_as(@user)

      get tasks_searches_path, params: { q: @task.name, completed: "false" }
      assert_response :success
      assert_match(/0 results/, response.body)

      get tasks_searches_path, params: { q: @task.name, completed: "true" }
      assert_response :success
      assert_match(/search-result__name.*#{Regexp.escape(@task.name)}/m, response.body)
    end
  end
end
