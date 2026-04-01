require "test_helper"

class SuggestionRoutingServiceTest < ActiveSupport::TestCase
  setup do
    # Deactivate fixture configs to isolate tests
    SuggestionConfig.update_all(active: false)
  end

  test "returns nil when no active config exists" do
    assert_nil SuggestionRoutingService.select_entry
  end

  test "returns the single entry when config has one entry" do
    model = llm_models(:gpt_turbo)
    prompt_set = prompt_sets(:general)

    config = SuggestionConfig.create_with_entries!(
      entries_attributes: [{ llm_model_id: model.id, prompt_set_id: prompt_set.id, weight: 100 }],
    )

    assert_equal config.entries.first, SuggestionRoutingService.select_entry
  end

  test "selects entry based on weight using rand" do
    model1 = llm_models(:gpt_turbo)
    model2 = llm_models(:gpt4)
    ps1 = prompt_sets(:general)
    ps2 = prompt_sets(:coding)

    config = SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: model1.id, prompt_set_id: ps1.id, weight: 70 },
        { llm_model_id: model2.id, prompt_set_id: ps2.id, weight: 30 },
      ],
    )
    entry1, entry2 = config.entries.order(:id).to_a

    # rand returns 0.0-0.69 → entry1 (weight 70)
    Kernel.stubs(:rand).returns(0.5)
    assert_equal entry1, SuggestionRoutingService.select_entry

    # rand returns 0.70-0.99 → entry2 (weight 30)
    Kernel.stubs(:rand).returns(0.8)
    assert_equal entry2, SuggestionRoutingService.select_entry
  end

  test "selects entry at weight boundary correctly" do
    model1 = llm_models(:gpt_turbo)
    model2 = llm_models(:gpt4)
    ps1 = prompt_sets(:general)
    ps2 = prompt_sets(:coding)

    config = SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: model1.id, prompt_set_id: ps1.id, weight: 70 },
        { llm_model_id: model2.id, prompt_set_id: ps2.id, weight: 30 },
      ],
    )
    entry1, entry2 = config.entries.order(:id).to_a

    # Exactly at boundary (0.70) → should select entry2
    Kernel.stubs(:rand).returns(0.70)
    assert_equal entry2, SuggestionRoutingService.select_entry

    # Just before boundary (0.69) → should select entry1
    Kernel.stubs(:rand).returns(0.69)
    assert_equal entry1, SuggestionRoutingService.select_entry
  end
end
