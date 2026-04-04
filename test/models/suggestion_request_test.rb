require "test_helper"

class SuggestionRequestTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  CLEANUP_MODELS = [
    SuggestionOutcome,
    SuggestedTask,
    SuggestionResponse,
    SuggestionRequest,
    SuggestionSession,
    SuggestionConfigEntry,
    SuggestionConfig,
    Prompt,
    PromptSet,
    Comment,
    Task,
    ProjectMember,
    Project,
    LlmModel,
    LlmProvider,
    UserRole,
    RolePermission,
    Role,
    Permission,
    User,
  ].freeze

  def setup
    @suggestion_request = suggestion_requests(:one)
    @session = suggestion_sessions(:one)
    @llm_model = llm_models(:gpt_turbo)
  end

  def teardown
    CLEANUP_MODELS.each(&:delete_all)
  end

  # === Associations ===

  test "belongs to suggestion_session" do
    assert_equal @session, @suggestion_request.suggestion_session
  end

  test "belongs to llm_model optionally" do
    association = SuggestionRequest.reflect_on_association(:llm_model)
    assert_equal :belongs_to, association.macro
    assert association.options[:optional]
  end

  test "belongs to suggestion_config_entry optionally" do
    association = SuggestionRequest.reflect_on_association(:suggestion_config_entry)
    assert_equal :belongs_to, association.macro
    assert association.options[:optional]
  end

  test "has one response" do
    response = @suggestion_request.build_response(
      raw_response: '{"tasks": []}',
      completion_tokens: 10,
      prompt_tokens: 20,
    )
    response.save!

    assert_equal response, @suggestion_request.response
  end

  # === request_params ===

  test "returns parsed raw_request with indifferent access" do
    request = SuggestionRequest.create!(
      suggestion_session: @session,
      raw_request: { model: "gpt-4.1-mini", messages: [], temperature: 0.7 }.to_json,
    )

    params = request.request_params
    assert_equal "gpt-4.1-mini", params[:model]
    assert_equal "gpt-4.1-mini", params["model"]
    assert_equal 0.7, params[:temperature]
  end

  test "request_params works after reload" do
    request = SuggestionRequest.create!(
      suggestion_session: @session,
      raw_request: { model: "claude-3-sonnet", messages: [] }.to_json,
    )
    request.reload

    params = request.request_params
    assert_equal "claude-3-sonnet", params[:model]
    assert_equal "claude-3-sonnet", params["model"]
  end

  # === No validations on request itself (moved to session) ===

  test "valid with just suggestion_session" do
    request = SuggestionRequest.new(
      suggestion_session: @session,
      raw_request: "{}",
    )
    assert request.valid?
  end

  test "invalid without suggestion_session" do
    request = SuggestionRequest.new(raw_request: "{}")
    assert_not request.valid?
    assert request.errors[:suggestion_session].any?
  end
end
