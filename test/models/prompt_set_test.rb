require "test_helper"

class PromptSetTest < ActiveSupport::TestCase
  test "should be valid with name" do
    prompt_set = PromptSet.new(name: "Test Prompt Set")
    assert prompt_set.valid?
  end

  test "should require name" do
    prompt_set = PromptSet.new(name: nil)
    assert_not prompt_set.valid?
    assert prompt_set.errors[:name].present?
  end

  test "should require unique name" do
    PromptSet.create!(name: "Unique Name")
    duplicate = PromptSet.new(name: "Unique Name")
    assert_not duplicate.valid?
    assert duplicate.errors[:name].present?
  end

  test "should default active to true" do
    prompt_set = PromptSet.create!(name: "Active Set")
    assert prompt_set.active?
  end

  test "should have many prompts ordered by position" do
    prompt_set = PromptSet.create!(name: "Ordered Set")
    prompt_set.prompts.create!(role: "user", body: "Second", position: 2)
    prompt_set.prompts.create!(role: "system", body: "First", position: 1)

    assert_equal "First", prompt_set.prompts.first.body
    assert_equal "Second", prompt_set.prompts.last.body
  end

  test "should accept nested attributes for prompts" do
    prompt_set = PromptSet.create!(
      name: "Nested Set",
      prompts_attributes: [
        { role: "system", body: "System prompt", position: 1 },
        { role: "user", body: "User prompt", position: 2 },
      ],
    )
    assert_equal 2, prompt_set.prompts.count
  end

  test "should prevent deactivation when used in active suggestion config" do
    prompt_set = PromptSet.create!(name: "Used Set")
    model = llm_models(:gpt4)
    SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: model.id, prompt_set_id: prompt_set.id, weight: 100 },
      ],
    )

    prompt_set.active = false
    assert_not prompt_set.valid?
    assert_includes prompt_set.errors[:active], "cannot be deactivated while used in an active suggestion config"
  end

  test "should allow deactivation when not used in active suggestion config" do
    prompt_set = PromptSet.create!(name: "Unused Set")
    prompt_set.active = false
    assert prompt_set.valid?
  end
end
