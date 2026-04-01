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
      request_body = build_request_body(
        model: model,
        options: options,
        system_messages: system_messages,
        non_system_messages: non_system_messages,
      )

      response = http_request(
        :post,
        "#{BASE_URL}/messages",
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: request_body.to_json,
      )

      build_chat_response(response)
    end

    def json_output_options(structured_output: nil, json_only: false)
      return build_output_config(structured_output) if structured_output_enabled?(structured_output)
      return { output_config: { format: { type: "json" } } } if json_only

      {}
    end

    private

      def structured_output_enabled?(structured_output)
        structured_output.is_a?(Hash) && structured_output[:enabled]
      end

      def build_output_config(structured_output)
        {
          output_config: {
            format: {
              type: "json_schema",
              schema: structured_output[:schema],
            },
          },
        }
      end

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

      def build_request_body(model:, options:, system_messages:, non_system_messages:)
        request_body = {
          model: model,
          max_tokens: options[:max_tokens] || 1000,
          temperature: options[:temperature] || 0.7,
        }.merge(options.except(:max_tokens, :temperature))
        add_system_prompt!(request_body, system_messages)
        request_body[:messages] = format_messages(non_system_messages)
        request_body
      end

      def add_system_prompt!(request_body, system_messages)
        return unless system_messages.any?

        request_body[:system] = system_messages.map { |message| message[:content] || message["content"] }.join("\n")
      end

      def build_chat_response(response)
        {
          content: response.dig("content", 0, "text"),
          model: response["model"],
          usage: normalize_usage(response["usage"]),
          stop_reason: response["stop_reason"],
        }
      end
  end
end
