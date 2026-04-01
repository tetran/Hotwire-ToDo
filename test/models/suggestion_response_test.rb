require "test_helper"

class SuggestionResponseTest < ActiveSupport::TestCase
  def setup
    @request = suggestion_requests(:one)
  end

  test "batch_create creates response with tasks from normalized LLM response" do
    normalized_response = {
      content: '{"tasks":[{"name":"Task 1","description":"Description 1","due_date":"2024/01/15"}]}',
      model: "gpt-4.1-mini",
      usage: { input_tokens: 100, output_tokens: 50 },
    }

    response = SuggestionResponse.batch_create(@request, normalized_response)

    assert_not_nil response.id
    assert_equal @request, response.suggestion_request
    assert_equal 50, response.completion_tokens
    assert_equal 100, response.prompt_tokens
    assert_equal 1, response.suggested_tasks.count
    assert_equal "Task 1", response.suggested_tasks.first.name
  end

  test "batch_create stores raw_response as JSON" do
    normalized_response = {
      content: '{"tasks":[{"name":"Task 1","description":"Desc","due_date":"2024/01/15"}]}',
      model: "gpt-4.1-mini",
      usage: { input_tokens: 20, output_tokens: 10 },
    }

    response = SuggestionResponse.batch_create(@request, normalized_response)
    parsed = JSON.parse(response.raw_response)
    assert_equal "gpt-4.1-mini", parsed["model"]
  end

  test "batch_create creates multiple suggested tasks" do
    normalized_response = {
      content: {
        tasks: [
          { name: "Task 1", description: "D1", due_date: "2024/01/10" },
          { name: "Task 2", description: "D2", due_date: "2024/01/15" },
        ],
      }.to_json,
      model: "gpt-4.1-mini",
      usage: { input_tokens: 50, output_tokens: 30 },
    }

    response = SuggestionResponse.batch_create(@request, normalized_response)
    assert_equal 2, response.suggested_tasks.count
  end

  test "batch_create handles missing usage gracefully" do
    normalized_response = {
      content: '{"tasks":[{"name":"Task 1","description":"D1","due_date":"2024/01/10"}]}',
      model: "gpt-4.1-mini",
    }

    response = SuggestionResponse.batch_create(@request, normalized_response)
    assert_equal 0, response.completion_tokens
    assert_equal 0, response.prompt_tokens
  end

  test "has one suggestion_outcome" do
    response = SuggestionResponse.create!(
      suggestion_request: @request,
      raw_response: "{}",
      completion_tokens: 10,
      prompt_tokens: 20,
    )
    outcome = SuggestionOutcome.create!(
      suggestion_response: response,
      total_suggested: 5,
      total_adopted: 3,
    )

    assert_equal outcome, response.suggestion_outcome
  end

  test "destroys suggestion_outcome when destroyed" do
    response = SuggestionResponse.create!(
      suggestion_request: @request,
      raw_response: "{}",
      completion_tokens: 10,
      prompt_tokens: 20,
    )
    SuggestionOutcome.create!(
      suggestion_response: response,
      total_suggested: 5,
      total_adopted: 3,
    )

    assert_difference "SuggestionOutcome.count", -1 do
      response.destroy!
    end
  end
end
