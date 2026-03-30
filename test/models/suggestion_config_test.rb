require "test_helper"

class SuggestionConfigTest < ActiveSupport::TestCase
  def setup
    @prompt_set = PromptSet.create!(name: "Test Prompt Set")
    @model1 = llm_models(:gpt4)
    @model2 = llm_models(:claude)
  end

  test "should be valid with entries totaling 100" do
    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: @model1, prompt_set: @prompt_set, weight: 100)
    assert config.valid?
  end

  test "should require weights to sum to 100" do
    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: @model1, prompt_set: @prompt_set, weight: 50)
    assert_not config.valid?
    assert_includes config.errors[:base], "Weights must sum to 100"
  end

  test "should allow max 3 entries" do
    prompt_set2 = PromptSet.create!(name: "Set 2")
    prompt_set3 = PromptSet.create!(name: "Set 3")
    prompt_set4 = PromptSet.create!(name: "Set 4")

    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: @model1, prompt_set: @prompt_set, weight: 25)
    config.entries.build(llm_model: @model1, prompt_set: prompt_set2, weight: 25)
    config.entries.build(llm_model: @model2, prompt_set: prompt_set3, weight: 25)
    config.entries.build(llm_model: @model2, prompt_set: prompt_set4, weight: 25)

    assert_not config.valid?
    assert_includes config.errors[:entries], "cannot have more than 3 entries"
  end

  test "should prevent duplicate model-prompt_set combinations" do
    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: @model1, prompt_set: @prompt_set, weight: 50)
    config.entries.build(llm_model: @model1, prompt_set: @prompt_set, weight: 50)

    assert_not config.valid?
    assert_includes config.errors[:entries], "cannot have duplicate model and prompt set combinations"
  end

  test "should only allow active models" do
    inactive_model = LlmModel.create!(
      llm_provider: llm_providers(:openai),
      name: "inactive-model",
      display_name: "Inactive",
      active: false,
    )
    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: inactive_model, prompt_set: @prompt_set, weight: 100)

    assert_not config.valid?
    assert_includes config.errors[:entries], "must only reference active models"
  end

  test "current should return active config" do
    config = SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: @model1.id, prompt_set_id: @prompt_set.id, weight: 100 },
      ],
    )
    assert_equal config, SuggestionConfig.current
  end

  test "current should return nil when no active config" do
    assert_nil SuggestionConfig.current
  end

  test "should default active to true" do
    config = SuggestionConfig.new
    assert config.active?
  end

  test "should only allow active prompt sets" do
    inactive_ps = PromptSet.create!(name: "Inactive PS", active: false)
    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: @model1, prompt_set: inactive_ps, weight: 100)

    assert_not config.valid?
    assert_includes config.errors[:entries], "must only reference active prompt sets"
  end

  test "should require at least one entry" do
    config = SuggestionConfig.new(active: false)
    assert_not config.valid?
    assert_includes config.errors[:entries], "must have at least one entry"
  end

  test "should not raise TypeError when entry has nil weight" do
    config = SuggestionConfig.new(active: false)
    config.entries.build(llm_model: @model1, prompt_set: @prompt_set, weight: nil)

    assert_nothing_raised { config.valid? }
    assert_not config.valid?
  end

  test "should allow destroying entries via nested attributes" do
    config = SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: @model1.id, prompt_set_id: @prompt_set.id, weight: 100 },
      ],
    )
    entry = config.entries.first

    config.update!(
      entries_attributes: [
        { id: entry.id, _destroy: true },
        { llm_model_id: @model2.id, prompt_set_id: @prompt_set.id, weight: 100 },
      ],
    )

    config.reload
    assert_equal 1, config.entries.size
    assert_equal @model2.id, config.entries.first.llm_model_id
  end
end
