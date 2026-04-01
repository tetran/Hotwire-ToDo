require "test_helper"
require "llm_client/anthropic"

module LlmClient
  class AnthropicTest < ActiveSupport::TestCase
    def setup
      @client = LlmClient::Anthropic.new(api_key: "test-api-key")
    end

    test "should initialize with api key" do
      assert_equal "test-api-key", @client.instance_variable_get(:@api_key)
    end

    test "should fetch models from API" do
      stub_models_request

      models = @client.models

      assert_equal 2, models.length
      assert_equal "claude-3-opus-20240229", models.first[:id]
      assert_equal "claude-3-opus-20240229", models.first[:name]
      assert_equal "Claude 3 Opus", models.first[:display_name]
      assert models.first[:created]
    end

    test "should handle chat completion" do
      stub_chat_request

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(messages: messages, model: "claude-3-opus-20240229")

      assert_equal "Hello! How can I assist you today?", response[:content]
      assert_equal "claude-3-opus-20240229", response[:model]
      assert_equal "end_turn", response[:stop_reason]
    end

    test "should normalize usage to input_tokens and output_tokens" do
      stub_chat_request

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(messages: messages, model: "claude-3-opus-20240229")

      assert_equal 10, response[:usage][:input_tokens]
      assert_equal 15, response[:usage][:output_tokens]
    end

    test "should separate system messages to top-level system parameter" do
      expected_body = {
        model: "claude-3-opus-20240229",
        max_tokens: 1000,
        temperature: 0.7,
        system: "You are a helpful assistant.",
        messages: [{ role: "user", content: "Hello" }],
      }

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          body: expected_body.to_json,
          headers: {
            "x-api-key" => "test-api-key",
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
          },
        )
        .to_return(status: 200, body: {
          content: [{ text: "Hi!" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 5, output_tokens: 3 },
          stop_reason: "end_turn",
        }.to_json)

      messages = [
        { role: "system", content: "You are a helpful assistant." },
        { role: "user", content: "Hello" },
      ]
      response = @client.chat(messages: messages, model: "claude-3-opus-20240229")

      assert_equal "Hi!", response[:content]
    end

    test "should concatenate multiple system messages" do
      expected_body = {
        model: "claude-3-opus-20240229",
        max_tokens: 1000,
        temperature: 0.7,
        system: "You are a helpful assistant.\nBe concise.",
        messages: [{ role: "user", content: "Hello" }],
      }

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          body: expected_body.to_json,
          headers: {
            "x-api-key" => "test-api-key",
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
          },
        )
        .to_return(status: 200, body: {
          content: [{ text: "Hi!" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 5, output_tokens: 3 },
          stop_reason: "end_turn",
        }.to_json)

      messages = [
        { role: "system", content: "You are a helpful assistant." },
        { role: "system", content: "Be concise." },
        { role: "user", content: "Hello" },
      ]
      response = @client.chat(messages: messages, model: "claude-3-opus-20240229")

      assert_equal "Hi!", response[:content]
    end

    test "should not include system parameter when no system messages" do
      expected_body = {
        model: "claude-3-opus-20240229",
        max_tokens: 1000,
        temperature: 0.7,
        messages: [{ role: "user", content: "Hello" }],
      }

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          body: expected_body.to_json,
          headers: {
            "x-api-key" => "test-api-key",
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
          },
        )
        .to_return(status: 200, body: {
          content: [{ text: "Hi!" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 5, output_tokens: 3 },
          stop_reason: "end_turn",
        }.to_json)

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(messages: messages, model: "claude-3-opus-20240229")

      assert_equal "Hi!", response[:content]
    end

    test "should pass temperature and extra options in request body" do
      expected_body = {
        model: "claude-3-opus-20240229",
        max_tokens: 2000,
        temperature: 0.5,
        top_p: 0.9,
        messages: [{ role: "user", content: "Hello" }],
      }

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          body: expected_body.to_json,
          headers: {
            "x-api-key" => "test-api-key",
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
          },
        )
        .to_return(status: 200, body: {
          content: [{ text: "Hi!" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 5, output_tokens: 3 },
          stop_reason: "end_turn",
        }.to_json)

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(
        messages: messages,
        model: "claude-3-opus-20240229",
        max_tokens: 2000,
        temperature: 0.5,
        top_p: 0.9,
      )

      assert_equal "Hi!", response[:content]
    end

    test "should use default temperature when not specified" do
      expected_body = {
        model: "claude-3-opus-20240229",
        max_tokens: 1000,
        temperature: 0.7,
        messages: [{ role: "user", content: "Hello" }],
      }

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          body: expected_body.to_json,
          headers: {
            "x-api-key" => "test-api-key",
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
          },
        )
        .to_return(status: 200, body: {
          content: [{ text: "Hi!" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 5, output_tokens: 3 },
          stop_reason: "end_turn",
        }.to_json)

      messages = [{ role: "user", content: "Hello" }]
      response = @client.chat(messages: messages, model: "claude-3-opus-20240229")

      assert_equal "Hi!", response[:content]
    end

    test "should handle API errors gracefully" do
      stub_request(:get, "https://api.anthropic.com/v1/models")
        .to_return(status: 401, body: '{"error": "Unauthorized"}')

      assert_raises(LlmClient::ApiError) do
        @client.models
      end
    end

    test "should provide output_config schema options" do
      options = @client.json_output_options(
        structured_output: {
          enabled: true,
          schema_name: "emit_tasks_json",
          schema: { type: "object", additionalProperties: false },
          strict: true,
        },
        json_only: true,
      )

      assert_equal "json_schema", options.dig(:output_config, :format, :type)
      assert_equal({ type: "object", additionalProperties: false }, options.dig(:output_config, :format, :schema))
      assert_not options.dig(:output_config, :format).key?(:name)
    end

    test "should include output_config in request body" do
      expected_body = {
        model: "claude-3-opus-20240229",
        max_tokens: 1000,
        temperature: 0.7,
        messages: [{ role: "user", content: "Hello" }],
        output_config: {
          format: {
            type: "json_schema",
            schema: {
              type: "object",
              additionalProperties: false,
            },
          },
        },
      }

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          headers: {
            "x-api-key" => "test-api-key",
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
          },
        )
        .with do |request|
          JSON.parse(request.body) == JSON.parse(expected_body.to_json)
        end
        .to_return(status: 200, body: {
          content: [{ text: "{\"tasks\":[]}" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 10, output_tokens: 15 },
          stop_reason: "end_turn",
        }.to_json)

      response = @client.chat(
        messages: [{ role: "user", content: "Hello" }],
        model: "claude-3-opus-20240229",
        output_config: expected_body[:output_config],
      )
      assert_equal "{\"tasks\":[]}", response[:content]
    end

    private

      def stub_models_request
        response_body = {
          data: [
            {
              id: "claude-3-opus-20240229",
              display_name: "Claude 3 Opus",
              created_at: "2024-02-29T00:00:00Z",
            },
            {
              id: "claude-3-sonnet-20240229",
              display_name: "Claude 3 Sonnet",
              created_at: "2024-02-29T00:00:00Z",
            },
          ],
        }.to_json

        stub_request(:get, "https://api.anthropic.com/v1/models")
          .with(headers: {
                  "x-api-key" => "test-api-key",
                  "anthropic-version" => "2023-06-01",
                })
          .to_return(status: 200, body: response_body)
      end

      def stub_chat_request
        response_body = {
          content: [{ text: "Hello! How can I assist you today?" }],
          model: "claude-3-opus-20240229",
          usage: { input_tokens: 10, output_tokens: 15 },
          stop_reason: "end_turn",
        }.to_json

        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .with(headers: {
                  "x-api-key" => "test-api-key",
                  "anthropic-version" => "2023-06-01",
                  "Content-Type" => "application/json",
                })
          .to_return(status: 200, body: response_body)
      end
  end
end
