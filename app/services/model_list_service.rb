class ModelListService
  class << self
    def fetch_models(provider_name, api_key, **)
      client = LlmClientFactory.create_client(provider_name, api_key, **)
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
  end
end
