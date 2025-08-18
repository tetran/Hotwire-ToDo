require_relative "base"

module LlmClient
  class Gemini < Base
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta".freeze

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
      # Format model name for API endpoint
      model_path = model.include?("/") ? model : "models/#{model}"

      request_body = {
        contents: format_contents(messages),
        generationConfig: {
          maxOutputTokens: options[:max_tokens] || 1000,
          temperature: options[:temperature] || 0.7,
        }.merge(options[:generation_config] || {}),
      }

      response = http_request(
        :post,
        "#{BASE_URL}/#{model_path}:generateContent",
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: request_body.to_json,
      )

      candidate = response.dig("candidates", 0)

      {
        content: candidate.dig("content", "parts", 0, "text"),
        model: model,
        usage: response["usageMetadata"],
        finish_reason: candidate["finishReason"],
      }
    end

    private

      def default_headers
        {
          "x-goog-api-key" => api_key,
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
  end
end
