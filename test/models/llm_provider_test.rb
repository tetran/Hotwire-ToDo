require "test_helper"

class LlmProviderTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    # Clear all providers to avoid conflicts
    SuggestionResponse.destroy_all
    SuggestionRequest.delete_all
    LlmModel.delete_all
    LlmProvider.delete_all
    
    @provider = LlmProvider.create!(
      name: "OpenAI",
      api_endpoint: "https://api.openai.com/v1",
      api_key: "test-api-key",
      active: true
    )
  end

  def teardown
    SuggestionResponse.destroy_all
    SuggestionRequest.delete_all
    LlmModel.delete_all
    LlmProvider.delete_all
  end

  test "should create provider with valid attributes" do
    provider = LlmProvider.new(
      name: "Anthropic",
      api_endpoint: "https://api.anthropic.com/v1",
      api_key: "test-key"
    )
    assert provider.valid?
  end

  test "should require name" do
    @provider.name = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:name], "can't be blank"
  end

  test "should require api_key_encrypted" do
    @provider.api_key = nil
    assert_not @provider.valid?
    assert_includes @provider.errors[:api_key_encrypted], "can't be blank"
  end

  test "should require unique name" do
    duplicate = LlmProvider.new(
      name: @provider.name,
      api_key: "another-key"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should encrypt and decrypt api_key" do
    original_key = "secret-api-key-456"
    @provider.api_key = original_key
    @provider.save!

    assert_not_equal original_key, @provider.api_key_encrypted
    assert_equal original_key, @provider.api_key
  end

  test "should handle nil api_key" do
    @provider.api_key = nil
    assert_nil @provider.api_key_encrypted
    assert_nil @provider.api_key
  end

  test "should handle empty api_key" do
    @provider.api_key = ""
    assert_nil @provider.api_key_encrypted
    assert_nil @provider.api_key
  end

  test "should default active to true" do
    provider = LlmProvider.create!(name: "Gemini", api_key: "key")
    assert provider.active?
  end

  test "should scope active providers" do
    # Use existing fixture data to avoid duplicate names
    @provider.update!(active: true)
    inactive_provider = LlmProvider.create!(name: "Gemini", api_key: "key", active: false)

    assert_includes LlmProvider.active, @provider
    assert_not_includes LlmProvider.active, inactive_provider
  end

  test "should have many llm_models" do
    model = @provider.llm_models.create!(
      name: "gpt-4",
      display_name: "GPT-4"
    )
    assert_includes @provider.llm_models, model
  end

  test "should destroy associated models when provider is destroyed" do
    model = @provider.llm_models.create!(
      name: "gpt-4",
      display_name: "GPT-4"
    )
    model_id = model.id

    SuggestionRequest.where(llm_model: @provider.llm_models).destroy_all

    @provider.destroy!
    assert_not LlmModel.exists?(model_id)
  end
end
