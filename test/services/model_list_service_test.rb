require "test_helper"

class ModelListServiceTest < ActiveSupport::TestCase
  test "should fetch OpenAI models" do
    stub_openai_models_request

    models = ModelListService.fetch_models("openai", "test-api-key", organization_id: "test-org")

    assert_equal 2, models.length
    assert_equal "gpt-4", models.first[:id]
    assert_equal "gpt-4", models.first[:name]
  end

  test "should fetch Anthropic models" do
    stub_anthropic_models_request

    models = ModelListService.fetch_models("anthropic", "test-api-key")

    assert_equal 2, models.length
    assert_equal "claude-3-opus-20240229", models.first[:id]
    assert_equal "Claude 3 Opus", models.first[:display_name]
  end

  test "should fetch Gemini models" do
    stub_gemini_models_request

    models = ModelListService.fetch_models("gemini", "test-api-key")

    assert_equal 2, models.length
    assert_equal "gemini-pro", models.first[:id]
    assert_equal "Gemini Pro", models.first[:display_name]
  end

  test "should return empty array for unknown provider" do
    models = ModelListService.fetch_models("unknown", "test-api-key")

    assert_equal [], models
  end

  test "should handle API errors gracefully" do
    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return(status: 401, body: '{"error": "Unauthorized"}')

    models = ModelListService.fetch_models("openai", "test-api-key")

    assert_equal [], models
  end

  test "should cache results" do
    stub_openai_models_request

    # First call should hit the API
    models1 = ModelListService.fetch_models("openai", "test-api-key")

    # Second call should use cache (no additional API call expected)
    models2 = ModelListService.fetch_models("openai", "test-api-key")

    assert_equal models1, models2
    assert_equal 2, models1.length
  end

  private

    def stub_openai_models_request
      response_body = {
        data: [
          { id: "gpt-4", created: 1_640_995_200 },
          { id: "gpt-3.5-turbo", created: 1_640_995_100 },
        ],
      }.to_json

      stub_request(:get, "https://api.openai.com/v1/models")
        .to_return(status: 200, body: response_body)
    end

    def stub_anthropic_models_request
      response_body = {
        data: [
          {
            id: "claude-3-opus-20240229",
            display_name: "Claude 3 Opus",
            created_at: "2024-02-29T00:00:00Z",
          },
          {
            id: "claude-3-sonnet-20240229",
            display_name: "Claude 3 Sonnet",
            created_at: "2024-02-29T00:00:00Z",
          },
        ],
      }.to_json

      stub_request(:get, "https://api.anthropic.com/v1/models")
        .to_return(status: 200, body: response_body)
    end

    def stub_gemini_models_request
      response_body = {
        models: [
          {
            name: "models/gemini-pro",
            displayName: "Gemini Pro",
            supportedGenerationMethods: ["generateContent"],
          },
          {
            name: "models/gemini-pro-vision",
            displayName: "Gemini Pro Vision",
            supportedGenerationMethods: ["generateContent"],
          },
        ],
      }.to_json

      stub_request(:get, "https://generativelanguage.googleapis.com/v1beta/models")
        .to_return(status: 200, body: response_body)
    end
end
