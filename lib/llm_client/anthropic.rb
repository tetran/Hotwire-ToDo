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
      system_messages, non_system_messages = partition_system_messages(messages)

      request_body = {
        model: model,
        max_tokens: options[:max_tokens] || 1000,
        temperature: options[:temperature] || 0.7,
      }.merge(options.except(:max_tokens, :temperature))

      request_body[:system] = system_messages.map { |m| m[:content] || m["content"] }.join("\n") if system_messages.any?

      request_body[:messages] = format_messages(non_system_messages)

      response = http_request(
        :post,
        "#{BASE_URL}/messages",
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: request_body.to_json,
      )

      {
        content: response.dig("content", 0, "text"),
        model: response["model"],
        usage: normalize_usage(response["usage"]),
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

      def normalize_usage(usage)
        return {} unless usage

        {
          input_tokens: usage["input_tokens"],
          output_tokens: usage["output_tokens"],
        }
      end

      def partition_system_messages(messages)
        messages.partition { |m| (m[:role] || m["role"]) == "system" }
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
