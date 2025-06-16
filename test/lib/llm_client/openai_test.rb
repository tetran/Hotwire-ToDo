require 'test_helper'
require 'llm_client/openai'

class LlmClient::OpenaiTest < ActiveSupport::TestCase
  def setup
    @client = LlmClient::Openai.new(
      api_key: 'test-api-key',
      organization_id: 'test-org-id'
    )
  end

  test "should initialize with api key and organization id" do
    assert_equal 'test-api-key', @client.instance_variable_get(:@api_key)
    assert_equal 'test-org-id', @client.instance_variable_get(:@organization_id)
  end

  test "should fetch models from API" do
    stub_models_request
    
    models = @client.models
    
    assert_equal 2, models.length
    assert_equal 'gpt-4', models.first[:id]
    assert_equal 'gpt-4', models.first[:name]
    assert models.first[:created]
  end

  test "should handle chat completion" do
    stub_chat_request
    
    messages = [{ role: 'user', content: 'Hello' }]
    response = @client.chat(messages: messages, model: 'gpt-4')
    
    assert_equal 'Hello! How can I help you?', response[:content]
    assert_equal 'gpt-4', response[:model]
    assert response[:usage]
    assert_equal 'stop', response[:finish_reason]
  end

  test "should handle API errors gracefully" do
    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return(status: 401, body: '{"error": "Unauthorized"}')
    
    assert_raises(LlmClient::ApiError) do
      @client.models
    end
  end

  private

  def stub_models_request
    response_body = {
      data: [
        { id: 'gpt-4', created: 1640995200 },
        { id: 'gpt-3.5-turbo', created: 1640995100 }
      ]
    }.to_json

    stub_request(:get, "https://api.openai.com/v1/models")
      .with(headers: {
        'Authorization' => 'Bearer test-api-key',
        'OpenAI-Organization' => 'test-org-id'
      })
      .to_return(status: 200, body: response_body)
  end

  def stub_chat_request
    response_body = {
      choices: [{
        message: { content: 'Hello! How can I help you?' },
        finish_reason: 'stop'
      }],
      model: 'gpt-4',
      usage: { total_tokens: 20 }
    }.to_json

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(headers: {
        'Authorization' => 'Bearer test-api-key',
        'OpenAI-Organization' => 'test-org-id',
        'Content-Type' => 'application/json'
      })
      .to_return(status: 200, body: response_body)
  end
end
