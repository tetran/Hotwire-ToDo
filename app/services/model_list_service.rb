class ModelListService
  require "llm_client/openai"
  require "llm_client/anthropic"
  require "llm_client/gemini"

  class << self
    def fetch_models(provider_name, api_key, **)
      client = create_client(provider_name, api_key, **)
      return [] unless client

      Rails.cache.fetch("models_#{provider_name}_#{api_key.first(8)}", expires_in: 1.hour) do
        client.models
      end
    rescue LlmClient::ApiError => e
      Rails.logger.error "API Error fetching models for #{provider_name}: #{e.message}"
      []
    rescue StandardError => e
      Rails.logger.error "Failed to fetch models for #{provider_name}: #{e.message}"
      []
    end

    private

      def create_client(provider_name, api_key, **options)
        case provider_name.downcase
        when "openai"
          LlmClient::Openai.new(
            api_key: api_key,
            organization_id: options[:organization_id],
          )
        when "anthropic"
          LlmClient::Anthropic.new(api_key: api_key)
        when "gemini", "google"
          LlmClient::Gemini.new(api_key: api_key)
        end
      end
  end
end
