require_relative "base"

module LlmClient
  class Openai < Base
    BASE_URL = "https://api.openai.com/v1".freeze

    def initialize(api_key:, organization_id: nil, **)
      super(api_key: api_key, **)
      @organization_id = organization_id
    end

    def models
      response = http_request(
        :get,
        "#{BASE_URL}/models",
        headers: default_headers,
      )

      # Filter to only include models that support chat completion
      models = response["data"] || []
      chat_models = models.select { |model| model["id"].include?("gpt") }

      chat_models.map do |model|
        {
          id: model["id"],
          name: model["id"],
          created: model["created"],
        }
      end
    end

    def chat(messages:, model:, **options)
      request_body = {
        model: model,
        messages: format_messages(messages),
        max_tokens: options[:max_tokens] || 1000,
        temperature: options[:temperature] || 0.7,
      }.merge(options.except(:max_tokens, :temperature))

      response = http_request(
        :post,
        "#{BASE_URL}/chat/completions",
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: request_body.to_json,
      )

      {
        content: response.dig("choices", 0, "message", "content"),
        model: response["model"],
        usage: normalize_usage(response["usage"]),
        finish_reason: response.dig("choices", 0, "finish_reason"),
      }
    end

    def json_output_options(structured_output: nil, json_only: false)
      return build_json_schema_output(structured_output) if structured_output_enabled?(structured_output)
      return { response_format: { type: "json_object" } } if json_only

      {}
    end

    private

      attr_reader :organization_id

      def structured_output_enabled?(structured_output)
        structured_output.is_a?(Hash) && structured_output[:enabled]
      end

      def build_json_schema_output(structured_output)
        {
          response_format: {
            type: "json_schema",
            json_schema: {
              name: structured_output[:schema_name],
              schema: structured_output[:schema],
              strict: structured_output.fetch(:strict, true),
            },
          },
        }
      end

      def default_headers
        headers = { "Authorization" => "Bearer #{api_key}" }
        headers["OpenAI-Organization"] = organization_id if organization_id
        headers
      end

      def normalize_usage(usage)
        return {} unless usage

        {
          input_tokens: usage["prompt_tokens"],
          output_tokens: usage["completion_tokens"],
        }
      end

      def format_messages(messages)
        messages.map do |message|
          {
            role: message[:role] || message["role"],
            content: message[:content] || message["content"],
          }
        end
      end
  end
end
