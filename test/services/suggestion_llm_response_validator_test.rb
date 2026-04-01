require "test_helper"

class SuggestionLlmResponseValidatorTest < ActiveSupport::TestCase
  setup do
    @validator = SuggestionLlmResponseValidator.new
  end

  test "returns false when content is not valid json" do
    valid, reason = @validator.validate("not json")

    assert_equal false, valid
    assert_equal "invalid JSON", reason
  end

  test "returns false when content is nil" do
    valid, reason = @validator.validate(nil)

    assert_equal false, valid
    assert_equal "invalid JSON", reason
  end

  test "returns false when tasks is empty array" do
    content = { tasks: [] }.to_json

    valid, reason = @validator.validate(content)

    assert_equal false, valid
    assert_equal "tasks is not a non-empty array", reason
  end

  test "returns false when response has unexpected top-level key" do
    content = {
      tasks: [{ name: "Task", description: "Desc", due_date: "2026/04/01" }],
      metadata: { provider: "test" },
    }.to_json

    valid, reason = @validator.validate(content)

    assert_equal false, valid
    assert_equal "response includes unexpected top-level keys", reason
  end

  test "returns false when required key is missing" do
    content = { tasks: [{ name: "Task", due_date: "2026/04/01" }] }.to_json

    valid, reason = @validator.validate(content)

    assert_equal false, valid
    assert_equal "tasks include unexpected keys", reason
  end

  test "returns false when required value is blank" do
    content = {
      tasks: [{ name: "Task", description: "", due_date: "2026/04/01" }],
    }.to_json

    valid, reason = @validator.validate(content)

    assert_equal false, valid
    assert_equal "tasks missing required keys (name, description, due_date)", reason
  end

  test "returns true when payload matches strict schema" do
    content = {
      tasks: [{ name: "Task", description: "Desc", due_date: "2026/04/01" }],
    }.to_json

    valid, reason = @validator.validate(content)

    assert_equal true, valid
    assert_nil reason
  end
end
