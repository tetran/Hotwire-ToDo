require "test_helper"

class Admin::LlmProvidersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @regular_user = users(:regular_user)
    @llm_provider = llm_providers(:openai)
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

  # New/Create tests
  test "should get new" do
    login_as_admin
    get new_admin_llm_provider_path
    assert_response :success
    assert_select "h1", "New LLM Provider"
  end

  test "should create provider" do
    login_as_admin
    
    provider_name = "Test Provider #{Time.current.to_i}"
    post admin_llm_providers_path, params: {
      llm_provider: {
        name: provider_name,
        api_endpoint: "https://api.test-provider.com",
        api_key: "test-api-key",
        organization_id: "org-test",
        active: true
      }
    }
    
    # Check if creation was successful
    if response.redirect?
      created_provider = LlmProvider.find_by(name: provider_name)
      assert_not_nil created_provider, "Provider should have been created"
      assert_redirected_to admin_llm_provider_path(created_provider)
      assert_equal provider_name, created_provider.name
      assert_equal "https://api.test-provider.com", created_provider.api_endpoint
      assert created_provider.active?
      assert_not_nil created_provider.api_key_encrypted
    else
      # If not redirected, check for validation errors
      assert_response :unprocessable_entity
      flunk "Provider creation failed. Response body: #{response.body}"
    end
  end

  test "should not create provider with invalid data" do
    login_as_admin
    assert_no_difference("LlmProvider.count") do
      post admin_llm_providers_path, params: {
        llm_provider: {
          name: "",
          api_endpoint: "",
          api_key: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not create provider with duplicate name" do
    login_as_admin
    assert_no_difference("LlmProvider.count") do
      post admin_llm_providers_path, params: {
        llm_provider: {
          name: @llm_provider.name,
          api_endpoint: "https://example.com",
          api_key: "test-key"
        }
      }
    end
    assert_response :unprocessable_entity
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
        name: "Updated OpenAI",
        organization_id: "new-org-id",
        active: false
      }
    }
    
    assert_redirected_to admin_llm_provider_path(@llm_provider)
    @llm_provider.reload
    assert_equal "Updated OpenAI", @llm_provider.name
    assert_equal "new-org-id", @llm_provider.organization_id
    assert_not @llm_provider.active?
  end

  test "should update provider without changing api key when blank" do
    login_as_admin
    original_api_key_encrypted = @llm_provider.api_key_encrypted
    
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: {
        name: "Updated Name",
        api_key: ""  # Blank API key should not change existing key
      }
    }
    
    assert_redirected_to admin_llm_provider_path(@llm_provider)
    @llm_provider.reload
    assert_equal "Updated Name", @llm_provider.name
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

  test "should not update provider with invalid data" do
    login_as_admin
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: {
        name: ""
      }
    }
    assert_response :unprocessable_entity
  end

  # Delete tests
  test "should destroy provider when no models have suggestion requests" do
    login_as_admin
    
    # Create a provider without any suggestion requests
    test_provider = LlmProvider.create!(
      name: "Test Provider",
      api_endpoint: "https://test.com",
      api_key: "test-key"
    )
    
    assert_difference("LlmProvider.count", -1) do
      delete admin_llm_provider_path(test_provider)
    end
    assert_redirected_to admin_llm_providers_path
  end

  test "should not destroy provider when models have suggestion requests" do
    login_as_admin
    
    # @llm_provider has models with suggestion requests from fixtures
    assert_no_difference("LlmProvider.count") do
      delete admin_llm_provider_path(@llm_provider)
    end
    assert_redirected_to admin_llm_providers_path
    assert_match /Cannot delete provider/, flash[:alert]
  end

  # Authorization tests
  test "all admin actions require admin access" do
    login_as(@regular_user)
    
    # Index
    get admin_llm_providers_path
    assert_admin_access_required
    
    # Show
    get admin_llm_provider_path(@llm_provider)
    assert_admin_access_required
    
    # New
    get new_admin_llm_provider_path
    assert_admin_access_required
    
    # Create
    post admin_llm_providers_path, params: { llm_provider: { name: "Test" } }
    assert_admin_access_required
    
    # Edit
    get edit_admin_llm_provider_path(@llm_provider)
    assert_admin_access_required
    
    # Update
    patch admin_llm_provider_path(@llm_provider), params: { llm_provider: { name: "Test" } }
    assert_admin_access_required
    
    # Delete
    delete admin_llm_provider_path(@llm_provider)
    assert_admin_access_required
  end

  # Granular permission tests for issue #125
  test "user with only Admin:read permission can access read-only actions" do
    # Create user with only Admin:read permission
    admin_read_user = users(:user_manager)  # user_manager has Admin:read permission
    login_as(admin_read_user)
    
    # Should be able to access index
    get admin_llm_providers_path
    assert_response :success
    
    # Should be able to access show
    get admin_llm_provider_path(@llm_provider)
    assert_response :success
  end

  test "user with only Admin:read permission cannot access write actions" do
    # Use no_role_user and manually assign only Admin:read permission
    read_only_user = users(:no_role_user)
    admin_read_permission = Permission.find_or_create_by!(resource_type: 'Admin', action: 'read') do |p|
      p.description = '管理画面の閲覧'
    end
    read_only_role = Role.create!(name: 'test_read_only', system_role: false)
    read_only_role.permissions << admin_read_permission
    read_only_user.roles << read_only_role
    
    login_as(read_only_user)
    
    # Should not be able to access new - redirected with error
    get new_admin_llm_provider_path
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
    
    # Should not be able to create - redirected with error
    post admin_llm_providers_path, params: {
      llm_provider: { name: "Test Provider", api_endpoint: "https://test.com", api_key: "test" }
    }
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
    
    # Should not be able to access edit - redirected with error
    get edit_admin_llm_provider_path(@llm_provider)
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
    
    # Should not be able to update - redirected with error
    patch admin_llm_provider_path(@llm_provider), params: {
      llm_provider: { name: "Updated Name" }
    }
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
  end

  test "user with only Admin:read permission cannot delete" do
    # Use no_role_user and manually assign only Admin:read permission
    read_only_user = users(:no_role_user)
    admin_read_permission = Permission.find_or_create_by!(resource_type: 'Admin', action: 'read') do |p|
      p.description = '管理画面の閲覧'
    end
    read_only_role = Role.create!(name: 'test_read_only_delete', system_role: false)
    read_only_role.permissions << admin_read_permission
    read_only_user.roles << read_only_role
    
    login_as(read_only_user)
    
    # Should not be able to delete - redirected with error
    delete admin_llm_provider_path(@llm_provider)
    assert_response :redirect
    assert_match /権限がありません/, flash[:error]
  end

  test "user with Admin:write permission can create and edit but not delete" do
    # This test will fail until we implement granular permissions
    # but it defines the expected behavior
    skip "Requires implementation of granular Admin permissions"
    
    # admin_write_user = create_user_with_admin_write_permission
    # login_as(admin_write_user)
    
    # # Should be able to read
    # get admin_llm_providers_path
    # assert_response :success
    
    # # Should be able to create
    # post admin_llm_providers_path, params: {
    #   llm_provider: { name: "Test Provider", api_endpoint: "https://test.com", api_key: "test" }
    # }
    # assert_response :redirect
    
    # # Should be able to edit
    # get edit_admin_llm_provider_path(@llm_provider)
    # assert_response :success
    
    # # Should not be able to delete
    # delete admin_llm_provider_path(@llm_provider)
    # assert_response :forbidden
  end

  test "user with Admin:delete permission can delete" do
    # This test will fail until we implement granular permissions
    skip "Requires implementation of granular Admin permissions"
    
    # admin_delete_user = create_user_with_admin_delete_permission
    # login_as(admin_delete_user)
    
    # # Should be able to delete
    # test_provider = LlmProvider.create!(
    #   name: "Test Provider",
    #   api_endpoint: "https://test.com", 
    #   api_key: "test-key"
    # )
    # delete admin_llm_provider_path(test_provider)
    # assert_response :redirect
  end

  test "user with Admin:manage permission has full access" do
    # admin_user fixture should have Admin:manage permission
    login_as(@admin_user)
    
    # Should be able to read
    get admin_llm_providers_path
    assert_response :success
    
    # Should be able to create
    post admin_llm_providers_path, params: {
      llm_provider: { 
        name: "Test Provider #{Time.current.to_i}", 
        api_endpoint: "https://test.com", 
        api_key: "test" 
      }
    }
    assert_response :redirect
    
    # Should be able to edit
    get edit_admin_llm_provider_path(@llm_provider)
    assert_response :success
    
    # Should be able to delete (test with provider that has no dependencies)
    test_provider = LlmProvider.create!(
      name: "Test Provider for Delete",
      api_endpoint: "https://test.com",
      api_key: "test-key"
    )
    delete admin_llm_provider_path(test_provider)
    assert_response :redirect
  end
end
