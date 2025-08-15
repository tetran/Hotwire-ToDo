require 'test_helper'

class Admin::AvailableModelsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @llm_provider = llm_providers(:openai)
    @llm_provider.api_key = 'test-api-key'
    @llm_provider.save!
  end

  test "should get available models for provider with API key" do
    login_as_admin
    
    ModelListService.expects(:fetch_models)
                    .with(@llm_provider.name, @llm_provider.api_key, organization_id: @llm_provider.organization_id)
                    .returns([
                      { id: 'gpt-4', name: 'gpt-4' },
                      { id: 'gpt-3.5-turbo', name: 'gpt-3.5-turbo' }
                    ])

    get admin_llm_provider_available_models_path(@llm_provider), 
        headers: { 'Accept' => 'application/json' }

    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['models'].length
    assert_equal 'gpt-4', json_response['models'].first['id']
  end

  test "should return error when provider has no API key" do
    login_as_admin
    @llm_provider.api_key = nil
    @llm_provider.save!(validate: false)

    get admin_llm_provider_available_models_path(@llm_provider),
        headers: { 'Accept' => 'application/json' }

    assert_response :unprocessable_content
    
    json_response = JSON.parse(response.body)
    assert_includes json_response['error'], 'API key not configured'
  end

  test "should handle service errors gracefully" do
    login_as_admin
    ModelListService.expects(:fetch_models).returns([])

    get admin_llm_provider_available_models_path(@llm_provider),
        headers: { 'Accept' => 'application/json' }

    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal [], json_response['models']
  end

  test "should require admin authentication" do
    get admin_llm_provider_available_models_path(@llm_provider),
        headers: { 'Accept' => 'application/json' }

    assert_redirected_to login_path
  end

  test "should return 404 for non-existent provider" do
    login_as_admin
    
    get admin_llm_provider_available_models_path(llm_provider_id: 999999),
        headers: { 'Accept' => 'application/json' }
    
    assert_response :not_found
  end
end
