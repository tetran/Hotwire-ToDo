require "test_helper"

class SuggestionOutcomeTest < ActiveSupport::TestCase
  def setup
    @suggestion_request = suggestion_requests(:one)
    @response = SuggestionResponse.create!(
      suggestion_request: @suggestion_request,
      raw_response: "{}",
      completion_tokens: 10,
      prompt_tokens: 20,
    )
  end

  test "should calculate acceptance_rate before save" do
    outcome = SuggestionOutcome.new(
      suggestion_response: @response,
      total_suggested: 10,
      total_adopted: 8,
    )
    outcome.save!
    assert_in_delta 80.0, outcome.acceptance_rate, 0.01
  end

  test "should set high_acceptance to true when acceptance_rate >= 80" do
    outcome = SuggestionOutcome.create!(
      suggestion_response: @response,
      total_suggested: 10,
      total_adopted: 8,
    )
    assert outcome.high_acceptance?
  end

  test "should set high_acceptance to false when acceptance_rate < 80" do
    outcome = SuggestionOutcome.create!(
      suggestion_response: @response,
      total_suggested: 10,
      total_adopted: 7,
    )
    assert_not outcome.high_acceptance?
  end

  test "should handle zero total_suggested" do
    outcome = SuggestionOutcome.create!(
      suggestion_response: @response,
      total_suggested: 0,
      total_adopted: 0,
    )
    assert_equal 0.0, outcome.acceptance_rate
    assert_not outcome.high_acceptance?
  end

  test "boundary: 80% exactly should be high_acceptance" do
    outcome = SuggestionOutcome.create!(
      suggestion_response: @response,
      total_suggested: 5,
      total_adopted: 4,
    )
    assert_in_delta 80.0, outcome.acceptance_rate, 0.01
    assert outcome.high_acceptance?
  end

  test "boundary: just below 80% should not be high_acceptance" do
    outcome = SuggestionOutcome.create!(
      suggestion_response: @response,
      total_suggested: 100,
      total_adopted: 79,
    )
    assert_in_delta 79.0, outcome.acceptance_rate, 0.01
    assert_not outcome.high_acceptance?
  end

  test "should belong to suggestion_response" do
    outcome = SuggestionOutcome.new(suggestion_response: @response)
    assert_equal @response, outcome.suggestion_response
  end

  test "should require total_suggested" do
    outcome = SuggestionOutcome.new(suggestion_response: @response, total_suggested: nil, total_adopted: 0)
    assert_not outcome.valid?
    assert outcome.errors.where(:total_suggested, :not_a_number).any?
  end

  test "should require total_adopted" do
    outcome = SuggestionOutcome.new(suggestion_response: @response, total_suggested: 10, total_adopted: nil)
    assert_not outcome.valid?
    assert outcome.errors.where(:total_adopted, :not_a_number).any?
  end

  test "should reject negative total_suggested" do
    outcome = SuggestionOutcome.new(suggestion_response: @response, total_suggested: -1, total_adopted: 0)
    assert_not outcome.valid?
    assert outcome.errors.where(:total_suggested, :greater_than_or_equal_to).any?
  end

  test "should reject negative total_adopted" do
    outcome = SuggestionOutcome.new(suggestion_response: @response, total_suggested: 10, total_adopted: -1)
    assert_not outcome.valid?
    assert outcome.errors.where(:total_adopted, :greater_than_or_equal_to).any?
  end

  test "should reject total_adopted greater than total_suggested" do
    outcome = SuggestionOutcome.new(suggestion_response: @response, total_suggested: 5, total_adopted: 6)
    assert_not outcome.valid?
    assert_includes outcome.errors[:total_adopted], "cannot exceed total_suggested"
  end
end
