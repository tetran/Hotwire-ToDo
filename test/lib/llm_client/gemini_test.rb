require 'test_helper'
require 'llm_client/gemini'

class LlmClient::GeminiTest < ActiveSupport::TestCase
  def setup
    @client = LlmClient::Gemini.new(api_key: 'test-api-key')
  end

  test "should initialize with api key" do
    assert_equal 'test-api-key', @client.instance_variable_get(:@api_key)
  end

  test "should fetch models from API" do
    stub_models_request
    
    models = @client.models
    
    assert_equal 2, models.length
    assert_equal 'gemini-pro', models.first[:id]
    assert_equal 'gemini-pro', models.first[:name]
    assert_equal 'Gemini Pro', models.first[:display_name]
  end

  test "should handle chat completion" do
    stub_chat_request
    
    messages = [{ role: 'user', content: 'Hello' }]
    response = @client.chat(messages: messages, model: 'gemini-pro')
    
    assert_equal 'Hello! How can I help you today?', response[:content]
    assert_equal 'gemini-pro', response[:model]
    assert response[:usage]
    assert_equal 'STOP', response[:finish_reason]
  end

  test "should handle API errors gracefully" do
    stub_request(:get, "https://generativelanguage.googleapis.com/v1beta/models")
      .to_return(status: 401, body: '{"error": "Unauthorized"}')
    
    assert_raises(LlmClient::ApiError) do
      @client.models
    end
  end

  private

  def stub_models_request
    response_body = {
      models: [
        {
          name: 'models/gemini-pro',
          displayName: 'Gemini Pro',
          description: 'The best model for scaling across a wide range of tasks',
          supportedGenerationMethods: ['generateContent']
        },
        {
          name: 'models/gemini-pro-vision',
          displayName: 'Gemini Pro Vision',
          description: 'The best image understanding model to handle a broad range of applications',
          supportedGenerationMethods: ['generateContent']
        }
      ]
    }.to_json

    stub_request(:get, "https://generativelanguage.googleapis.com/v1beta/models")
      .with(headers: { 'x-goog-api-key' => 'test-api-key' })
      .to_return(status: 200, body: response_body)
  end

  def stub_chat_request
    response_body = {
      candidates: [{
        content: {
          parts: [{ text: 'Hello! How can I help you today?' }]
        },
        finishReason: 'STOP'
      }],
      usageMetadata: { totalTokenCount: 25 }
    }.to_json

    stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")
      .with(headers: {
        'x-goog-api-key' => 'test-api-key',
        'Content-Type' => 'application/json'
      })
      .to_return(status: 200, body: response_body)
  end
end
