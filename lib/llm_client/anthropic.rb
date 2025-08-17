require_relative "base"

module LlmClient
  class Anthropic < Base
    BASE_URL = "https://api.anthropic.com/v1".freeze
    API_VERSION = "2023-06-01".freeze

    def models
      response = http_request(
        :get,
        "#{BASE_URL}/models",
        headers: default_headers,
      )

      models = response["data"] || []

      models.map do |model|
        {
          id: model["id"],
          name: model["id"],
          display_name: model["display_name"],
          created: model["created_at"],
        }
      end
    end

    def chat(messages:, model:, **options)
      request_body = {
        model: model,
        max_tokens: options[:max_tokens] || 1000,
        messages: format_messages(messages),
      }

      response = http_request(
        :post,
        "#{BASE_URL}/messages",
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: request_body.to_json,
      )

      {
        content: response.dig("content", 0, "text"),
        model: response["model"],
        usage: response["usage"],
        stop_reason: response["stop_reason"],
      }
    end

    private

      def default_headers
        {
          "x-api-key" => api_key,
          "anthropic-version" => API_VERSION,
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
