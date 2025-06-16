require_relative 'base'

module LlmClient
  class Openai < Base
    BASE_URL = 'https://api.openai.com/v1'

    def initialize(api_key:, organization_id: nil, **options)
      super(api_key: api_key, **options)
      @organization_id = organization_id
    end

    def models
      response = http_request(
        :get,
        "#{BASE_URL}/models",
        headers: default_headers
      )

      # Filter to only include models that support chat completion
      models = response['data'] || []
      chat_models = models.select { |model| model['id'].include?('gpt') }
      
      chat_models.map do |model|
        {
          id: model['id'],
          name: model['id'],
          created: model['created']
        }
      end
    end

    def chat(messages:, model:, **options)
      request_body = {
        model: model,
        messages: format_messages(messages),
        max_tokens: options[:max_tokens] || 1000,
        temperature: options[:temperature] || 0.7
      }.merge(options.except(:max_tokens, :temperature))

      response = http_request(
        :post,
        "#{BASE_URL}/chat/completions",
        headers: default_headers.merge('Content-Type' => 'application/json'),
        body: request_body.to_json
      )

      {
        content: response.dig('choices', 0, 'message', 'content'),
        model: response['model'],
        usage: response['usage'],
        finish_reason: response.dig('choices', 0, 'finish_reason')
      }
    end

    private

    attr_reader :organization_id

    def default_headers
      headers = { 'Authorization' => "Bearer #{api_key}" }
      headers['OpenAI-Organization'] = organization_id if organization_id
      headers
    end

    def format_messages(messages)
      messages.map do |message|
        {
          role: message[:role] || message['role'],
          content: message[:content] || message['content']
        }
      end
    end
  end
end
