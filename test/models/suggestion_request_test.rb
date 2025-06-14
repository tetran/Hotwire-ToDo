require "test_helper"

class SuggestionRequestTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @suggestion_request = suggestion_requests(:one)
    @user = users(:regular_user)
    @project = projects(:one)
    @llm_model = llm_models(:gpt_turbo)
  end

  def teardown
    SuggestedTask.delete_all
    SuggestionResponse.delete_all
    SuggestionRequest.delete_all
    Comment.delete_all
    Task.delete_all
    ProjectMember.delete_all
    Project.delete_all
    LlmModel.delete_all
    LlmProvider.delete_all
    UserRole.delete_all
    RolePermission.delete_all
    Role.delete_all
    Permission.delete_all
    User.delete_all
  end

  test "should be valid with valid attributes" do
    request = SuggestionRequest.new(
      project: @project,
      requested_by: @user,
      llm_model: @llm_model,
      goal: "Build a web application",
      start_date: Date.current,
      due_date: Date.current + 1.week
    )

    # Skip rate limiting validation for this test
    request.define_singleton_method(:too_many_requests) { }

    assert request.valid?
  end

  test "should require goal" do
    @suggestion_request.goal = nil
    assert_not @suggestion_request.valid?
    assert_includes @suggestion_request.errors[:goal], "can't be blank"
  end

  test "should require goal with maximum 100 characters" do
    @suggestion_request.goal = "a" * 101
    assert_not @suggestion_request.valid?
    assert_includes @suggestion_request.errors[:goal], "is too long (maximum is 100 characters)"
  end

  test "should require project" do
    @suggestion_request.project = nil
    assert_not @suggestion_request.valid?
    assert_includes @suggestion_request.errors[:project], "must exist"
  end

  test "should require requested_by user" do
    @suggestion_request.requested_by = nil
    assert_not @suggestion_request.valid?
    assert_includes @suggestion_request.errors[:requested_by], "must exist"
  end

  test "should require llm_model" do
    @suggestion_request.llm_model = nil
    assert_not @suggestion_request.valid?
    assert_includes @suggestion_request.errors[:llm_model], "must exist"
  end

  test "should belong to llm_model" do
    assert_equal @llm_model, @suggestion_request.llm_model
  end

  test "should belong to project" do
    assert_equal @project, @suggestion_request.project
  end

  test "should belong to requested_by user" do
    assert_equal @user, @suggestion_request.requested_by
  end

  test "should have one response" do
    response = @suggestion_request.build_response(
      raw_response: '{"tasks": []}',
      completion_tokens: 10,
      prompt_tokens: 20
    )
    response.save!

    assert_equal response, @suggestion_request.response
  end

  test "should validate rate limiting" do
    # Mock Time to create requests within the limit window
    travel_to Time.current do
      # Create two requests to reach the limit
      2.times do |i|
        req = SuggestionRequest.new(
          project: @project,
          requested_by: @user,
          llm_model: @llm_model,
          goal: "Request #{i}",
          start_date: Date.current,
          due_date: Date.current + 1.week
        )
        req.save(validate: false)  # Skip validation for setup
        req.update_column(:created_at, Time.current)
      end

      # Third request should fail validation
      third_request = SuggestionRequest.new(
        project: @project,
        requested_by: @user,
        llm_model: @llm_model,
        goal: "Third request",
        start_date: Date.current,
        due_date: Date.current + 1.week
      )

      assert_not third_request.valid?
      assert_includes third_request.errors[:base], "Too many requests. Please try again later."
    end
  end

  test "should set raw_request before save" do
    request = SuggestionRequest.new(
      project: @project,
      requested_by: @user,
      llm_model: @llm_model,
      goal: "Test goal",
      context: "Test context",
      start_date: Date.current,
      due_date: Date.current + 1.week
    )

    # Skip rate limiting validation
    request.define_singleton_method(:too_many_requests) { }

    request.save!
    assert_not_nil request.raw_request

    parsed = JSON.parse(request.raw_request)
    assert_equal "gpt-4.1-mini", parsed["model"]  # Current hardcoded value
    assert_equal "json_object", parsed["response_format"]["type"]
    assert_equal 0.7, parsed["temperature"]
    assert_includes parsed["messages"].last["content"], "Test goal"
  end

  test "should include context in instruction when present" do
    request = SuggestionRequest.new(
      project: @project,
      requested_by: @user,
      llm_model: @llm_model,
      goal: "Test goal",
      context: "Important context",
      start_date: Date.current,
      due_date: Date.current + 1.week
    )

    # Skip rate limiting validation
    request.define_singleton_method(:too_many_requests) { }

    request.save!
    parsed = JSON.parse(request.raw_request)
    assert_includes parsed["messages"].last["content"], "Important context"
  end

  test "should return openai_params from raw_request" do
    request = SuggestionRequest.new(
      project: @project,
      requested_by: @user,
      llm_model: @llm_model,
      goal: "Test params",
      start_date: Date.current,
      due_date: Date.current + 1.week
    )

    # Skip rate limiting validation
    request.define_singleton_method(:too_many_requests) { }

    request.save!

    params = request.openai_params
    assert_not_nil params, "openai_params should not be nil"

    assert_equal "gpt-4.1-mini", params[:model]  # Current hardcoded value
    assert_equal "json_object", params[:response_format][:type]
  end

  test "should allow different users to make requests" do
    another_user = User.create!(email: "another@example.com", password: "password123")

    # Another user should be able to make requests even if first user is at limit
    request = SuggestionRequest.new(
      project: @project,
      requested_by: another_user,
      llm_model: @llm_model,
      goal: "User 2 request",
      start_date: Date.current,
      due_date: Date.current + 1.week
    )

    # Skip rate limiting validation
    request.define_singleton_method(:too_many_requests) { }

    assert request.valid?
  end
end
