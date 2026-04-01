require "test_helper"

class SuggestionOutcomeServiceTest < ActiveSupport::TestCase
  def setup
    @request = suggestion_requests(:one)
    @response = SuggestionResponse.create!(
      suggestion_request: @request,
      raw_response: "{}",
      completion_tokens: 10,
      prompt_tokens: 20,
    )
  end

  test "record_adoption calculates acceptance_rate" do
    create_suggested_tasks(@response, 5)

    outcome = SuggestionOutcomeService.record_adoption(
      suggestion_response: @response,
      adopted_count: 4,
    )

    assert_equal 5, outcome.total_suggested
    assert_equal 4, outcome.total_adopted
    assert_in_delta 80.0, outcome.acceptance_rate, 0.01
    assert outcome.high_acceptance?
  end

  test "record_adoption is idempotent" do
    create_suggested_tasks(@response, 1)

    first = SuggestionOutcomeService.record_adoption(
      suggestion_response: @response,
      adopted_count: 1,
    )
    second = SuggestionOutcomeService.record_adoption(
      suggestion_response: @response,
      adopted_count: 0,
    )

    assert_equal first.id, second.id
    # Does not update — returns existing
    assert_equal 1, second.total_adopted
  end

  test "record_abandonment creates outcome with 0% acceptance" do
    create_suggested_tasks(@response, 2)

    outcome = SuggestionOutcomeService.record_abandonment(suggestion_response: @response)

    assert outcome.persisted?
    assert_equal 2, outcome.total_suggested
    assert_equal 0, outcome.total_adopted
    assert_in_delta 0.0, outcome.acceptance_rate, 0.01
    assert_not outcome.high_acceptance?
  end

  test "record_abandonment is idempotent" do
    create_suggested_tasks(@response, 1)

    first = SuggestionOutcomeService.record_abandonment(suggestion_response: @response)
    second = SuggestionOutcomeService.record_abandonment(suggestion_response: @response)

    assert_equal first.id, second.id
  end

  test "record_adoption does not overwrite existing abandonment" do
    create_suggested_tasks(@response, 1)

    abandonment = SuggestionOutcomeService.record_abandonment(suggestion_response: @response)
    adoption = SuggestionOutcomeService.record_adoption(
      suggestion_response: @response,
      adopted_count: 1,
    )

    assert_equal abandonment.id, adoption.id
    assert_equal 0, adoption.total_adopted
  end

  test "record_adoption clamps adopted_count to total_suggested" do
    create_suggested_tasks(@response, 3)

    outcome = SuggestionOutcomeService.record_adoption(
      suggestion_response: @response,
      adopted_count: 10,
    )

    assert_equal 3, outcome.total_suggested
    assert_equal 3, outcome.total_adopted
    assert_in_delta 100.0, outcome.acceptance_rate, 0.01
  end

  test "record_adoption handles RecordNotUnique from race condition" do
    create_suggested_tasks(@response, 2)

    race_winner = SuggestionOutcome.create!(suggestion_response: @response, total_suggested: 2, total_adopted: 0)
    @response.stubs(:suggestion_outcome).returns(nil)
    @response.stubs(:create_suggestion_outcome!).raises(ActiveRecord::RecordNotUnique)

    result = SuggestionOutcomeService.record_adoption(suggestion_response: @response, adopted_count: 1)
    assert_equal race_winner.id, result.id
  end

  test "record_abandonment handles RecordNotUnique from race condition" do
    create_suggested_tasks(@response, 2)

    race_winner = SuggestionOutcome.create!(suggestion_response: @response, total_suggested: 2, total_adopted: 1)
    @response.stubs(:suggestion_outcome).returns(nil)
    @response.stubs(:create_suggestion_outcome!).raises(ActiveRecord::RecordNotUnique)

    result = SuggestionOutcomeService.record_abandonment(suggestion_response: @response)
    assert_equal race_winner.id, result.id
  end

  private

    def create_suggested_tasks(response, count)
      tasks = Array.new(count) do |i|
        { suggestion_response_id: response.id, name: "T#{i + 1}", description: "D#{i + 1}", due_date: Date.current }
      end
      SuggestedTask.insert_all!(tasks)
    end
end
