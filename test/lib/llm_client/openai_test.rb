require "test_helper"
require "llm_client/openai"

module LlmClient
  class OpenaiTest < ActiveSupport::TestCase
    def setup
      @client = LlmClient::Openai.new(
        api_key: "test-api-key",
        organization_id: "test-org-id",
      )
    end

    test "should initialize with api key and organization id" do
      assert_equal "test-api-key", @client.instance_variable_get(:@api_key)
      assert_equal "test-org-id", @client.instance_variable_get(:@organization_id)
    end

    test "should fetch models from API" do
      stub_models_request

      models = @client.models

      assert_equal 2, models.length
      assert_equal "gpt-4", models.first[:id]
      assert_equal "gpt-4", models.first[:name]
      assert models.first[:created]
    end

    test "should handle chat completion" do
      stub_chat_request

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(messages: messages, model: "gpt-4")

      assert_equal "Hello! How can I help you?", response[:content]
      assert_equal "gpt-4", response[:model]
      assert_equal "stop", response[:finish_reason]
    end

    test "should normalize usage to input_tokens and output_tokens" do
      stub_chat_request

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(messages: messages, model: "gpt-4")

      assert_equal 10, response[:usage][:input_tokens]
      assert_equal 15, response[:usage][:output_tokens]
    end

    test "should handle API errors gracefully" do
      stub_request(:get, "https://api.openai.com/v1/models")
        .to_return(status: 401, body: '{"error": "Unauthorized"}')

      assert_raises(LlmClient::ApiError) do
        @client.models
      end
    end

    test "should provide json schema output options" do
      options = @client.json_output_options(
        structured_output: {
          enabled: true,
          schema_name: "emit_tasks_json",
          schema: { type: "object" },
          strict: true,
        },
        json_only: true,
      )

      assert_equal "json_schema", options.dig(:response_format, :type)
      assert_equal "emit_tasks_json", options.dig(:response_format, :json_schema, :name)
      assert_equal true, options.dig(:response_format, :json_schema, :strict)
    end

    test "should include response_format in chat request body" do
      expected_body = {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }],
        max_tokens: 1000,
        temperature: 0.7,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "emit_tasks_json",
            schema: { type: "object", additionalProperties: false },
            strict: true,
          },
        },
      }

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(headers: {
                "Authorization" => "Bearer test-api-key",
                "OpenAI-Organization" => "test-org-id",
                "Content-Type" => "application/json",
              })
        .with do |request|
          JSON.parse(request.body) == JSON.parse(expected_body.to_json)
        end
        .to_return(status: 200, body: {
          choices: [{ message: { content: "{\"tasks\":[]}" }, finish_reason: "stop" }],
          model: "gpt-4",
          usage: { prompt_tokens: 10, completion_tokens: 15, total_tokens: 25 },
        }.to_json)

      messages = [{ role: "user", content: "Hello" }]
      @client.chat(
        messages: messages,
        model: "gpt-4",
        response_format: expected_body[:response_format],
      )

      assert_requested(:post, "https://api.openai.com/v1/chat/completions", times: 1)
    end

    private

      def stub_models_request
        response_body = {
          data: [
            { id: "gpt-4", created: 1_640_995_200 },
            { id: "gpt-3.5-turbo", created: 1_640_995_100 },
          ],
        }.to_json

        stub_request(:get, "https://api.openai.com/v1/models")
          .with(headers: {
                  "Authorization" => "Bearer test-api-key",
                  "OpenAI-Organization" => "test-org-id",
                })
          .to_return(status: 200, body: response_body)
      end

      def stub_chat_request
        response_body = {
          choices: [{
            message: { content: "Hello! How can I help you?" },
            finish_reason: "stop",
          }],
          model: "gpt-4",
          usage: { prompt_tokens: 10, completion_tokens: 15, total_tokens: 25 },
        }.to_json

        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(headers: {
                  "Authorization" => "Bearer test-api-key",
                  "OpenAI-Organization" => "test-org-id",
                  "Content-Type" => "application/json",
                })
          .to_return(status: 200, body: response_body)
      end
  end
end
