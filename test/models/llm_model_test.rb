require "test_helper"

class LlmModelTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @provider = llm_providers(:openai)
    @model = llm_models(:gpt4)
  end

  def teardown
    SuggestionOutcome.delete_all
    SuggestionResponse.destroy_all
    SuggestionRequest.delete_all
    SuggestionConfigEntry.delete_all
    SuggestionConfig.delete_all
    Prompt.delete_all
    PromptSet.delete_all
    LlmModel.delete_all
    LlmProvider.delete_all
  end

  test "should create model with valid attributes" do
    model = @provider.llm_models.new(
      name: "gpt-4",
      display_name: "GPT-4",
    )
    assert model.valid?
  end

  test "should require name" do
    @model.name = nil
    assert_not @model.valid?
    assert @model.errors[:name].present?
  end

  test "should require display_name" do
    @model.display_name = nil
    assert_not @model.valid?
    assert @model.errors[:display_name].present?
  end

  test "should require unique name within provider" do
    duplicate = @provider.llm_models.new(
      name: @model.name,
      display_name: "Another Display Name",
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:name].present?
  end

  test "should allow same name across different providers" do
    another_provider = llm_providers(:anthropic)
    model = another_provider.llm_models.new(
      name: @model.name,
      display_name: "Claude",
    )
    assert model.valid?
  end

  test "should default active to true" do
    model = @provider.llm_models.create!(
      name: "new-model",
      display_name: "New Model",
    )
    assert model.active?
  end

  test "should scope active models" do
    active_model = @provider.llm_models.create!(
      name: "active-model",
      display_name: "Active Model",
      active: true,
    )
    inactive_model = @provider.llm_models.create!(
      name: "inactive-model",
      display_name: "Inactive Model",
      active: false,
    )

    assert_includes LlmModel.active, active_model
    assert_not_includes LlmModel.active, inactive_model
  end

  test "should return full_name combining provider and display name" do
    expected = "#{@provider.name} - #{@model.display_name}"
    assert_equal expected, @model.full_name
  end

  test "should belong to llm_provider" do
    assert_equal @provider, @model.llm_provider
  end

  test "should prevent deactivation when used in active suggestion config" do
    prompt_set = PromptSet.create!(name: "Test PS")
    SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: @model.id, prompt_set_id: prompt_set.id, weight: 100 },
      ],
    )

    @model.active = false
    assert_not @model.valid?
    assert_includes @model.errors[:active], "cannot be deactivated while used in an active suggestion config"
  end

  test "should allow deactivation when not used in active suggestion config" do
    model = @provider.llm_models.create!(name: "unused-model", display_name: "Unused")
    model.active = false
    assert model.valid?
  end
end
