require "test_helper"

class Admin::LlmModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @regular_user = users(:regular_user)
    @llm_provider = llm_providers(:openai)
    @llm_model = llm_models(:gpt_turbo)
  end

  # Authentication tests
  test "should redirect to login when not authenticated" do
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_redirected_to login_path
  end

  test "should deny access to users without admin permissions" do
    login_as(@regular_user)
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_admin_access_required
  end

  # Index tests
  test "should get index for admin" do
    login_as_admin
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_response :success
    assert_select "h2", text: /Models/
  end

  test "should show models in index" do
    login_as_admin
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_response :success
    assert_select "tbody tr", minimum: 1
    assert_select "td", text: @llm_model.name
  end

  # Show tests
  test "should show model" do
    login_as_admin
    get admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :success
    assert_select "h1", @llm_model.display_name
  end

  test "should show model details in show page" do
    login_as_admin
    get admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :success
    assert_select "dt", text: "Name"
    assert_select "dd", text: @llm_model.name
    assert_select "dt", text: "Display Name"
    assert_select "dd", text: @llm_model.display_name
  end

  # New/Create tests
  test "should get new" do
    login_as_admin
    get new_admin_llm_provider_llm_model_path(@llm_provider)
    assert_response :success
    assert_select "h1", "New Model for #{@llm_provider.name}"
  end

  test "should create model" do
    login_as_admin
    
    post admin_llm_provider_llm_models_path(@llm_provider), params: {
      llm_model: {
        name: "gpt-4-turbo",
        display_name: "GPT-4 Turbo",
        active: true,
        default_model: false
      }
    }
    
    if response.redirect?
      created_model = @llm_provider.llm_models.find_by(name: "gpt-4-turbo")
      assert_not_nil created_model, "Model should have been created"
      assert_redirected_to admin_llm_provider_llm_model_path(@llm_provider, created_model)
      assert_equal "gpt-4-turbo", created_model.name
      assert_equal "GPT-4 Turbo", created_model.display_name
      assert created_model.active?
      assert_not created_model.default_model?
    else
      # If not redirected, check for validation errors
      assert_response :unprocessable_entity
      flunk "Model creation failed. Response body: #{response.body}"
    end
  end

  test "should create model as default and unset previous default" do
    login_as_admin
    
    # First, ensure we have a default model
    @llm_model.update!(default_model: true)
    assert @llm_model.default_model?
    
    assert_difference("@llm_provider.llm_models.count") do
      post admin_llm_provider_llm_models_path(@llm_provider), params: {
        llm_model: {
          name: "gpt-4-new",
          display_name: "GPT-4 New",
          default_model: true
        }
      }
    end
    
    created_model = @llm_provider.llm_models.last
    @llm_model.reload
    
    assert created_model.default_model?
    assert_not @llm_model.default_model?
  end

  test "should not create model with invalid data" do
    login_as_admin
    assert_no_difference("@llm_provider.llm_models.count") do
      post admin_llm_provider_llm_models_path(@llm_provider), params: {
        llm_model: {
          name: "",
          display_name: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not create model with duplicate name within provider" do
    login_as_admin
    assert_no_difference("@llm_provider.llm_models.count") do
      post admin_llm_provider_llm_models_path(@llm_provider), params: {
        llm_model: {
          name: @llm_model.name,
          display_name: "Duplicate Model"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should allow same model name across different providers" do
    login_as_admin
    another_provider = LlmProvider.create!(
      name: "Anthropic #{Time.current.to_i}",
      api_endpoint: "https://api.anthropic.com",
      api_key: "test-key"
    )
    
    assert_difference("another_provider.llm_models.count") do
      post admin_llm_provider_llm_models_path(another_provider), params: {
        llm_model: {
          name: @llm_model.name,  # Same name as existing model
          display_name: "Claude Model"
        }
      }
    end
    assert_response :redirect
  end

  # Edit/Update tests
  test "should get edit" do
    login_as_admin
    get edit_admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :success
    assert_select "h1", "Edit #{@llm_model.display_name}"
  end

  test "should update model" do
    login_as_admin
    patch admin_llm_provider_llm_model_path(@llm_provider, @llm_model), params: {
      llm_model: {
        display_name: "Updated GPT Model",
        active: false
      }
    }
    
    assert_redirected_to admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    @llm_model.reload
    assert_equal "Updated GPT Model", @llm_model.display_name
    assert_not @llm_model.active?
  end

  test "should update model to default and unset previous default" do
    login_as_admin
    
    # Create another model and make it default
    other_model = @llm_provider.llm_models.create!(
      name: "other-model",
      display_name: "Other Model",
      default_model: true
    )
    
    # Make sure current model is not default
    @llm_model.update!(default_model: false)
    
    patch admin_llm_provider_llm_model_path(@llm_provider, @llm_model), params: {
      llm_model: {
        default_model: true
      }
    }
    
    assert_redirected_to admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    @llm_model.reload
    other_model.reload
    
    assert @llm_model.default_model?
    assert_not other_model.default_model?
  end

  test "should not update model with invalid data" do
    login_as_admin
    patch admin_llm_provider_llm_model_path(@llm_provider, @llm_model), params: {
      llm_model: {
        name: "",
        display_name: ""
      }
    }
    assert_response :unprocessable_entity
  end

  # Delete tests
  test "should destroy model when not used by suggestion requests" do
    login_as_admin
    
    # Create a model without any suggestion requests
    test_model = @llm_provider.llm_models.create!(
      name: "test-model",
      display_name: "Test Model"
    )
    
    assert_difference("@llm_provider.llm_models.count", -1) do
      delete admin_llm_provider_llm_model_path(@llm_provider, test_model)
    end
    assert_redirected_to admin_llm_provider_path(@llm_provider)
  end

  test "should not destroy model when used by suggestion requests" do
    login_as_admin
    
    # @llm_model has suggestion requests from fixtures
    assert_no_difference("@llm_provider.llm_models.count") do
      delete admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    end
    assert_redirected_to admin_llm_provider_path(@llm_provider)
    assert_match /Cannot delete model/, flash[:alert]
  end

  # Provider scope tests
  test "should only show models for specific provider" do
    login_as_admin
    another_provider = LlmProvider.create!(
      name: "Anthropic #{Time.current.to_i}",
      api_endpoint: "https://api.anthropic.com",
      api_key: "test-key"
    )
    another_model = another_provider.llm_models.create!(
      name: "claude-3",
      display_name: "Claude 3"
    )
    
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_response :success
    
    # Should show OpenAI models
    assert_select "td", text: @llm_model.name
    # Should not show Anthropic models
    assert_select "td", text: another_model.name, count: 0
  end

  test "should handle non-existent provider" do
    login_as_admin
    get admin_llm_provider_llm_models_path(llm_provider_id: 99999)
    # Should return either 404 or redirect to error page
    assert_response 404
  rescue ActionController::RoutingError, ActiveRecord::RecordNotFound
    # This is expected behavior
  end

  test "should handle non-existent model" do
    login_as_admin
    get admin_llm_provider_llm_model_path(@llm_provider, id: 99999)
    # Should return either 404 or redirect to error page
    assert_response 404
  rescue ActionController::RoutingError, ActiveRecord::RecordNotFound
    # This is expected behavior
  end

  # Authorization tests
  test "all admin actions require admin access" do
    login_as(@regular_user)
    
    # Index
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_admin_access_required
    
    # Show
    get admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_admin_access_required
    
    # New
    get new_admin_llm_provider_llm_model_path(@llm_provider)
    assert_admin_access_required
    
    # Create
    post admin_llm_provider_llm_models_path(@llm_provider), params: { llm_model: { name: "Test" } }
    assert_admin_access_required
    
    # Edit
    get edit_admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_admin_access_required
    
    # Update
    patch admin_llm_provider_llm_model_path(@llm_provider, @llm_model), params: { llm_model: { name: "Test" } }
    assert_admin_access_required
    
    # Delete
    delete admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_admin_access_required
  end

  # Granular permission tests for issue #125
  test "user with only Admin:read permission can access read-only actions" do
    # Create user with only Admin:read permission
    admin_read_user = users(:user_manager)  # user_manager has Admin:read permission
    login_as(admin_read_user)
    
    # Should be able to access index
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_response :success
    
    # Should be able to access show
    get admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :success
  end

  test "user with only Admin:read permission cannot access write actions" do
    admin_read_user = users(:user_manager)
    login_as(admin_read_user)
    
    # Should not be able to access new
    get new_admin_llm_provider_llm_model_path(@llm_provider)
    assert_response :forbidden
    
    # Should not be able to create
    post admin_llm_provider_llm_models_path(@llm_provider), params: {
      llm_model: { name: "test-model", display_name: "Test Model" }
    }
    assert_response :forbidden
    
    # Should not be able to access edit
    get edit_admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :forbidden
    
    # Should not be able to update
    patch admin_llm_provider_llm_model_path(@llm_provider, @llm_model), params: {
      llm_model: { display_name: "Updated Name" }
    }
    assert_response :forbidden
  end

  test "user with only Admin:read permission cannot delete" do
    admin_read_user = users(:user_manager)
    login_as(admin_read_user)
    
    # Should not be able to delete
    delete admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :forbidden
  end

  test "user with Admin:write permission can create and edit but not delete" do
    # This test will fail until we implement granular permissions
    # but it defines the expected behavior
    skip "Requires implementation of granular Admin permissions"
    
    # admin_write_user = create_user_with_admin_write_permission
    # login_as(admin_write_user)
    
    # # Should be able to read
    # get admin_llm_provider_llm_models_path(@llm_provider)
    # assert_response :success
    
    # # Should be able to create
    # post admin_llm_provider_llm_models_path(@llm_provider), params: {
    #   llm_model: { name: "test-model", display_name: "Test Model" }
    # }
    # assert_response :redirect
    
    # # Should be able to edit
    # get edit_admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    # assert_response :success
    
    # # Should not be able to delete
    # delete admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    # assert_response :forbidden
  end

  test "user with Admin:delete permission can delete" do
    # This test will fail until we implement granular permissions
    skip "Requires implementation of granular Admin permissions"
    
    # admin_delete_user = create_user_with_admin_delete_permission
    # login_as(admin_delete_user)
    
    # # Should be able to delete
    # test_model = @llm_provider.llm_models.create!(
    #   name: "test-model",
    #   display_name: "Test Model"
    # )
    # delete admin_llm_provider_llm_model_path(@llm_provider, test_model)
    # assert_response :redirect
  end

  test "user with Admin:manage permission has full access" do
    # admin_user fixture should have Admin:manage permission
    login_as(@admin_user)
    
    # Should be able to read
    get admin_llm_provider_llm_models_path(@llm_provider)
    assert_response :success
    
    # Should be able to create
    post admin_llm_provider_llm_models_path(@llm_provider), params: {
      llm_model: { 
        name: "test-model-#{Time.current.to_i}", 
        display_name: "Test Model" 
      }
    }
    assert_response :redirect
    
    # Should be able to edit
    get edit_admin_llm_provider_llm_model_path(@llm_provider, @llm_model)
    assert_response :success
    
    # Should be able to delete (test with model that has no dependencies)
    test_model = @llm_provider.llm_models.create!(
      name: "test-model-for-delete",
      display_name: "Test Model for Delete"
    )
    delete admin_llm_provider_llm_model_path(@llm_provider, test_model)
    assert_response :redirect
  end
end
