require "test_helper"

class LlmModelTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @provider = llm_providers(:openai)
    @model = llm_models(:gpt_4)
  end

  def teardown
    SuggestionResponse.destroy_all
    SuggestionRequest.delete_all
    LlmModel.delete_all
    LlmProvider.delete_all
  end

  test "should create model with valid attributes" do
    model = @provider.llm_models.new(
      name: "gpt-4",
      display_name: "GPT-4"
    )
    assert model.valid?
  end

  test "should require name" do
    @model.name = nil
    assert_not @model.valid?
    assert_includes @model.errors[:name], "can't be blank"
  end

  test "should require display_name" do
    @model.display_name = nil
    assert_not @model.valid?
    assert_includes @model.errors[:display_name], "can't be blank"
  end

  test "should require unique name within provider" do
    duplicate = @provider.llm_models.new(
      name: @model.name,
      display_name: "Another Display Name"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should allow same name across different providers" do
    another_provider = llm_providers(:anthropic)
    model = another_provider.llm_models.new(
      name: @model.name,
      display_name: "Claude"
    )
    assert model.valid?
  end

  test "should default active to true" do
    model = @provider.llm_models.create!(
      name: "new-model",
      display_name: "New Model"
    )
    assert model.active?
  end

  test "should default default_model to false" do
    model = @provider.llm_models.create!(
      name: "new-model",
      display_name: "New Model"
    )
    assert_not model.default_model?
  end

  test "should scope active models" do
    active_model = @provider.llm_models.create!(
      name: "active-model",
      display_name: "Active Model",
      active: true
    )
    inactive_model = @provider.llm_models.create!(
      name: "inactive-model",
      display_name: "Inactive Model",
      active: false
    )

    assert_includes LlmModel.active, active_model
    assert_not_includes LlmModel.active, inactive_model
  end

  test "should scope default models" do
    default_model = @provider.llm_models.create!(
      name: "default-model",
      display_name: "Default Model",
      default_model: true
    )
    regular_model = @provider.llm_models.create!(
      name: "regular-model",
      display_name: "Regular Model",
      default_model: false
    )

    assert_includes LlmModel.default, default_model
    assert_not_includes LlmModel.default, regular_model
  end

  test "should return full_name combining provider and display name" do
    expected = "#{@provider.name} - #{@model.display_name}"
    assert_equal expected, @model.full_name
  end

  test "should automatically unset previous default when creating new default" do
    first_default = @provider.llm_models.create!(
      name: "first-default",
      display_name: "First Default",
      default_model: true
    )

    second_default = @provider.llm_models.create!(
      name: "second-default",
      display_name: "Second Default",
      default_model: true
    )

    first_default.reload
    assert_not first_default.default_model?
    assert second_default.default_model?
  end

  test "should allow multiple default models across different providers" do
    another_provider = llm_providers(:anthropic)

    @provider.llm_models.create!(
      name: "gpt-default",
      display_name: "GPT Default",
      default_model: true
    )

    claude_default = another_provider.llm_models.new(
      name: "claude-default",
      display_name: "Claude Default",
      default_model: true
    )

    assert claude_default.valid?
  end

  test "should unset other default models when setting new default" do
    first_default = @provider.llm_models.create!(
      name: "first-default",
      display_name: "First Default",
      default_model: true
    )

    second_model = @provider.llm_models.create!(
      name: "second-model",
      display_name: "Second Model"
    )

    second_model.update!(default_model: true)
    first_default.reload

    assert_not first_default.default_model?
    assert second_model.default_model?
  end

  test "should not affect default models of other providers" do
    another_provider = llm_providers(:anthropic)

    openai_default = @provider.llm_models.create!(
      name: "gpt-default",
      display_name: "GPT Default",
      default_model: true
    )

    claude_default = another_provider.llm_models.create!(
      name: "claude-default",
      display_name: "Claude Default",
      default_model: true
    )

    new_openai_default = @provider.llm_models.create!(
      name: "new-gpt-default",
      display_name: "New GPT Default",
      default_model: true
    )

    openai_default.reload
    claude_default.reload

    assert_not openai_default.default_model?
    assert claude_default.default_model?
    assert new_openai_default.default_model?
  end

  test "should belong to llm_provider" do
    assert_equal @provider, @model.llm_provider
  end
end
