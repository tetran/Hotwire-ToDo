require 'test_helper'
require 'llm_client/anthropic'

class LlmClient::AnthropicTest < ActiveSupport::TestCase
  def setup
    @client = LlmClient::Anthropic.new(api_key: 'test-api-key')
  end

  test "should initialize with api key" do
    assert_equal 'test-api-key', @client.instance_variable_get(:@api_key)
  end

  test "should fetch models from API" do
    stub_models_request
    
    models = @client.models
    
    assert_equal 2, models.length
    assert_equal 'claude-3-opus-20240229', models.first[:id]
    assert_equal 'claude-3-opus-20240229', models.first[:name]
    assert_equal 'Claude 3 Opus', models.first[:display_name]
    assert models.first[:created]
  end

  test "should handle chat completion" do
    stub_chat_request
    
    messages = [{ role: 'user', content: 'Hello' }]
    response = @client.chat(messages: messages, model: 'claude-3-opus-20240229')
    
    assert_equal 'Hello! How can I assist you today?', response[:content]
    assert_equal 'claude-3-opus-20240229', response[:model]
    assert response[:usage]
    assert_equal 'end_turn', response[:stop_reason]
  end

  test "should handle API errors gracefully" do
    stub_request(:get, "https://api.anthropic.com/v1/models")
      .to_return(status: 401, body: '{"error": "Unauthorized"}')
    
    assert_raises(LlmClient::ApiError) do
      @client.models
    end
  end

  private

  def stub_models_request
    response_body = {
      data: [
        {
          id: 'claude-3-opus-20240229',
          display_name: 'Claude 3 Opus',
          created_at: '2024-02-29T00:00:00Z'
        },
        {
          id: 'claude-3-sonnet-20240229',
          display_name: 'Claude 3 Sonnet',
          created_at: '2024-02-29T00:00:00Z'
        }
      ]
    }.to_json

    stub_request(:get, "https://api.anthropic.com/v1/models")
      .with(headers: {
        'x-api-key' => 'test-api-key',
        'anthropic-version' => '2023-06-01'
      })
      .to_return(status: 200, body: response_body)
  end

  def stub_chat_request
    response_body = {
      content: [{ text: 'Hello! How can I assist you today?' }],
      model: 'claude-3-opus-20240229',
      usage: { input_tokens: 10, output_tokens: 15 },
      stop_reason: 'end_turn'
    }.to_json

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with(headers: {
        'x-api-key' => 'test-api-key',
        'anthropic-version' => '2023-06-01',
        'Content-Type' => 'application/json'
      })
      .to_return(status: 200, body: response_body)
  end
end
