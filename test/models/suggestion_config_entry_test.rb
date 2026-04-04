require "test_helper"

class SuggestionConfigEntryTest < ActiveSupport::TestCase
  test "should require weight between 1 and 100" do
    entry = SuggestionConfigEntry.new(weight: 0)
    entry.valid?
    assert entry.errors.where(:weight, :greater_than_or_equal_to).any?

    entry.weight = 101
    entry.valid?
    assert entry.errors.where(:weight, :less_than_or_equal_to).any?
  end

  test "should accept weight of 1" do
    entry = SuggestionConfigEntry.new(
      suggestion_config: SuggestionConfig.new,
      llm_model: llm_models(:gpt4),
      prompt_set: PromptSet.create!(name: "Test"),
      weight: 1,
    )
    entry.valid?
    assert_not entry.errors.where(:weight, :greater_than_or_equal_to).any?
  end

  test "should accept weight of 100" do
    entry = SuggestionConfigEntry.new(
      suggestion_config: SuggestionConfig.new,
      llm_model: llm_models(:gpt4),
      prompt_set: PromptSet.create!(name: "Test 100"),
      weight: 100,
    )
    entry.valid?
    assert_not entry.errors.where(:weight, :less_than_or_equal_to).any?
  end

  test "should belong to suggestion_config" do
    assert_equal :belongs_to, SuggestionConfigEntry.reflect_on_association(:suggestion_config).macro
  end

  test "should belong to llm_model" do
    assert_equal :belongs_to, SuggestionConfigEntry.reflect_on_association(:llm_model).macro
  end

  test "should belong to prompt_set" do
    assert_equal :belongs_to, SuggestionConfigEntry.reflect_on_association(:prompt_set).macro
  end

  test "should prevent duplicate combination of suggestion_config, llm_model and prompt_set" do
    prompt_set = PromptSet.create!(name: "Dup Test")
    config = SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: llm_models(:gpt4).id, prompt_set_id: prompt_set.id, weight: 100 },
      ],
    )

    duplicate = SuggestionConfigEntry.new(
      suggestion_config: config,
      llm_model: llm_models(:gpt4),
      prompt_set: prompt_set,
      weight: 50,
    )
    assert_not duplicate.valid?
    assert duplicate.errors.where(:llm_model_id, :taken).any?
  end
end
