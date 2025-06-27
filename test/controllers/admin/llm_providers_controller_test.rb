require "test_helper"

class Admin::LlmProvidersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @regular_user = users(:regular_user)

    # Clean up all providers to avoid conflicts
    SuggestionResponse.destroy_all
    SuggestionRequest.delete_all
    LlmModel.delete_all
    LlmProvider.delete_all

    @llm_provider = LlmProvider.create!(
      name: 'OpenAI',
      api_endpoint: 'https://api.openai.com/v1',
      api_key: 'test-api-key',
      organization_id: 'org-test',
      active: true
    )
  end

  # Authentication tests
  test "should redirect to login when not authenticated" do
    get admin_llm_providers_path
    assert_redirected_to login_path
  end

  test "should deny access to users without admin permissions" do
    login_as(@regular_user)
    get admin_llm_providers_path
    assert_admin_access_required
  end

  # Index tests
  test "should get index for admin" do
    login_as_admin
    get admin_llm_providers_path
    assert_response :success
    assert_select "h1", "LLM Providers"
  end

  test "should show providers in index" do
    login_as_admin
    get admin_llm_providers_path
    assert_response :success
    assert_select "tbody tr", minimum: 1
    assert_select "td", text: @llm_provider.name
  end

  # Show tests
  test "should show provider" do
    login_as_admin
    get admin_llm_provider_path(@llm_provider)
    assert_response :success
    assert_select "h1", @llm_provider.name
  end

  test "should show provider models in show page" do
    login_as_admin
    get admin_llm_provider_path(@llm_provider)
    assert_response :success
    assert_select "h2", text: /Models/
  end

  # Edit/Update tests
  test "should get edit" do
    login_as_admin
    get edit_admin_llm_provider_path(@llm_provider)
    assert_response :success
    assert_select "h1", "Edit #{@llm_provider.name}"
  end

  test "should update provider" do
    login_as_admin
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: {
        organization_id: "new-org-id",
        active: false
      }
    }

    assert_redirected_to admin_llm_provider_path(@llm_provider)
    @llm_provider.reload
    assert_equal "new-org-id", @llm_provider.organization_id
    assert_not @llm_provider.active?
  end

  test "should update provider without changing api key when blank" do
    login_as_admin
    original_api_key_encrypted = @llm_provider.api_key_encrypted

    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: {
        api_key: ""  # Blank API key should not change existing key
      }
    }

    assert_redirected_to admin_llm_provider_path(@llm_provider)
    @llm_provider.reload
    assert_equal original_api_key_encrypted, @llm_provider.api_key_encrypted
  end

  test "should update api key when provided" do
    login_as_admin
    original_api_key_encrypted = @llm_provider.api_key_encrypted

    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: {
        api_key: "new-api-key"
      }
    }

    assert_redirected_to admin_llm_provider_path(@llm_provider)
    @llm_provider.reload
    assert_not_equal original_api_key_encrypted, @llm_provider.api_key_encrypted
  end

  test "should not update provider name" do
    login_as_admin
    original_name = @llm_provider.name
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: {
        name: "InvalidProvider",
        organization_id: "new-org"
      }
    }
    
    assert_redirected_to admin_llm_provider_path(@llm_provider)
    @llm_provider.reload
    assert_equal original_name, @llm_provider.name, "Provider name should not change"
    assert_equal "new-org", @llm_provider.organization_id, "Other fields should update"
  end

  # Authorization tests
  test "admin actions require appropriate permissions" do
    login_as(@regular_user)

    # Index
    get admin_llm_providers_path
    assert_admin_access_required

    # Show
    get admin_llm_provider_path(@llm_provider)
    assert_admin_access_required

    # Edit
    get edit_admin_llm_provider_path(@llm_provider)
    assert_admin_access_required

    # Update
    patch admin_llm_provider_path(@llm_provider), params: { llm_provider: { organization_id: "Test" } }
    assert_admin_access_required
  end

  # Granular permission tests
  test "user with only Admin:read permission can access read-only actions" do
    admin_read_user = users(:user_manager)  # user_manager has Admin:read permission
    login_as(admin_read_user)
    
    # Should be able to access index
    get admin_llm_providers_path
    assert_response :success
    
    # Should be able to access show
    get admin_llm_provider_path(@llm_provider)
    assert_response :success
  end

  test "user_manager can access write actions after migration" do
    user_manager = users(:user_manager)
    login_as(user_manager)
    
    # Should be able to access edit
    get edit_admin_llm_provider_path(@llm_provider)
    assert_response :success
    
    # Check actual permissions
    assert user_manager.can_read?('Admin'), "user_manager should have Admin:read"
    assert user_manager.can_write?('Admin'), "user_manager should have Admin:write"  
    assert_not user_manager.can_delete?('Admin'), "user_manager should NOT have Admin:delete"
  end

  test "user with only Admin:read permission cannot access write actions" do
    read_only_user = users(:no_role_user)
    admin_read_permission = Permission.find_or_create_by!(resource_type: 'Admin', action: 'read') do |p|
      p.description = '管理画面の閲覧'
    end
    read_only_role = Role.create!(name: 'test_read_only', system_role: false)
    read_only_role.permissions << admin_read_permission
    read_only_user.roles << read_only_role
    
    login_as(read_only_user)
    
    # Should not be able to access edit
    get edit_admin_llm_provider_path(@llm_provider)
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
    
    # Should not be able to update
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: { organization_id: "test" }
    }
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
  end

  test "user with Admin:manage permission has full access" do
    login_as(@admin_user)
    
    # Should be able to read
    get admin_llm_providers_path
    assert_response :success
    
    # Should be able to edit
    get edit_admin_llm_provider_path(@llm_provider)
    assert_response :success
    
    # Should be able to update
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: { 
        organization_id: "test-org"
      }
    }
    assert_response :redirect
  end
end