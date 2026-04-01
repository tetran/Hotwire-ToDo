require "test_helper"

class LlmClientFactoryTest < ActiveSupport::TestCase
  test "creates OpenAI client" do
    client = LlmClientFactory.create_client("openai", "test-key")
    assert_instance_of LlmClient::Openai, client
  end

  test "creates OpenAI client with organization_id" do
    client = LlmClientFactory.create_client("openai", "test-key", organization_id: "org-123")
    assert_instance_of LlmClient::Openai, client
  end

  test "creates Anthropic client" do
    client = LlmClientFactory.create_client("anthropic", "test-key")
    assert_instance_of LlmClient::Anthropic, client
  end

  test "creates Gemini client" do
    client = LlmClientFactory.create_client("gemini", "test-key")
    assert_instance_of LlmClient::Gemini, client
  end

  test "creates Gemini client with google alias" do
    client = LlmClientFactory.create_client("google", "test-key")
    assert_instance_of LlmClient::Gemini, client
  end

  test "is case insensitive for provider name" do
    client = LlmClientFactory.create_client("OpenAI", "test-key")
    assert_instance_of LlmClient::Openai, client
  end

  test "returns nil for unknown provider" do
    client = LlmClientFactory.create_client("unknown", "test-key")
    assert_nil client
  end

  test "creates client from LlmModel" do
    model = llm_models(:gpt4)
    LlmProvider.any_instance.stubs(:api_key).returns("test-key")
    client = LlmClientFactory.create_client_from_model(model)
    assert_instance_of LlmClient::Openai, client
  end

  test "creates client from Anthropic LlmModel" do
    model = llm_models(:claude)
    LlmProvider.any_instance.stubs(:api_key).returns("test-key")
    client = LlmClientFactory.create_client_from_model(model)
    assert_instance_of LlmClient::Anthropic, client
  end
end
