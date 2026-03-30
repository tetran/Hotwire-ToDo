class LlmClientFactory
  require "llm_client/openai"
  require "llm_client/anthropic"
  require "llm_client/gemini"

  class << self
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

    def create_client_from_model(llm_model)
      provider = llm_model.llm_provider
      create_client(
        provider.name,
        provider.api_key,
        organization_id: provider.organization_id,
      )
    end
  end
end
