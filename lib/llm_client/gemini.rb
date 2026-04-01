require_relative "base"

module LlmClient
  class Gemini < Base
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta".freeze
    DEFAULT_MAX_OUTPUT_TOKENS = 4000

    def models
      response = http_request(
        :get,
        "#{BASE_URL}/models",
        headers: default_headers,
      )

      models = response["models"] || []

      # Filter to only include models that support generateContent
      generation_models = models.select do |model|
        methods = model["supportedGenerationMethods"] || []
        methods.include?("generateContent")
      end

      generation_models.map do |model|
        {
          id: model["name"].split("/").last,
          name: model["name"].split("/").last,
          display_name: model["displayName"],
          description: model["description"],
        }
      end
    end

    def chat(messages:, model:, **options)
      system_messages, non_system_messages = partition_system_messages(messages)
      model_path = model_path_for(model)
      request_body = build_request_body(
        options: options,
        system_messages: system_messages,
        non_system_messages: non_system_messages,
      )

      response = http_request(
        :post,
        "#{BASE_URL}/#{model_path}:generateContent",
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: request_body.to_json,
      )

      build_chat_response(response: response, model: model)
    end

    def json_output_options(structured_output: nil, json_only: false)
      return build_structured_generation_config(structured_output) if structured_output_enabled?(structured_output)
      return { generation_config: { "responseMimeType" => "application/json" } } if json_only

      {}
    end

    private

      def structured_output_enabled?(structured_output)
        structured_output.is_a?(Hash) && structured_output[:enabled]
      end

      def build_structured_generation_config(structured_output)
        {
          generation_config: {
            "responseMimeType" => "application/json",
            "responseJsonSchema" => structured_output[:schema],
          },
        }
      end

      def default_headers
        {
          "x-goog-api-key" => api_key,
        }
      end

      def partition_system_messages(messages)
        messages.partition { |m| (m[:role] || m["role"]) == "system" }
      end

      def normalize_usage(usage)
        return {} unless usage

        {
          input_tokens: usage["promptTokenCount"],
          output_tokens: usage["candidatesTokenCount"],
        }
      end

      def format_contents(messages)
        messages.map do |message|
          role = case message[:role] || message["role"]
                 when "assistant"
                   "model"
                 else
                   "user"
                 end

          {
            role: role,
            parts: [{ text: message[:content] || message["content"] }],
          }
        end
      end

      def model_path_for(model)
        model.include?("/") ? model : "models/#{model}"
      end

      def build_request_body(options:, system_messages:, non_system_messages:)
        request_body = {
          contents: format_contents(non_system_messages),
          generationConfig: generation_config(options),
        }
        add_system_instruction!(request_body, system_messages)
        request_body
      end

      def generation_config(options)
        {
          maxOutputTokens: options[:max_tokens] || DEFAULT_MAX_OUTPUT_TOKENS,
          temperature: options[:temperature] || 0.7,
        }.merge(options[:generation_config] || {})
      end

      def add_system_instruction!(request_body, system_messages)
        return unless system_messages.any?

        system_text = system_messages.map { |message| message[:content] || message["content"] }.join("\n")
        request_body[:system_instruction] = { parts: [{ text: system_text }] }
      end

      def build_chat_response(response:, model:)
        candidate = response.dig("candidates", 0)
        {
          content: candidate.dig("content", "parts", 0, "text"),
          model: model,
          usage: normalize_usage(response["usageMetadata"]),
          finish_reason: candidate["finishReason"],
        }
      end
  end
end
