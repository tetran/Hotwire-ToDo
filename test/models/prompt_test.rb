require "test_helper"

class PromptTest < ActiveSupport::TestCase
  def setup
    @prompt_set = PromptSet.create!(name: "Test Set")
  end

  test "should be valid with all attributes" do
    prompt = @prompt_set.prompts.new(role: "system", body: "Hello", position: 1)
    assert prompt.valid?
  end

  test "should require role" do
    prompt = @prompt_set.prompts.new(role: nil, body: "Hello", position: 1)
    assert_not prompt.valid?
    assert_includes prompt.errors[:role], "can't be blank"
  end

  test "should require role to be system or user" do
    prompt = @prompt_set.prompts.new(role: "assistant", body: "Hello", position: 1)
    assert_not prompt.valid?
    assert_includes prompt.errors[:role], "is not included in the list"
  end

  test "should accept system role" do
    prompt = @prompt_set.prompts.new(role: "system", body: "Hello", position: 1)
    assert prompt.valid?
  end

  test "should accept user role" do
    prompt = @prompt_set.prompts.new(role: "user", body: "Hello", position: 1)
    assert prompt.valid?
  end

  test "should require body" do
    prompt = @prompt_set.prompts.new(role: "system", body: nil, position: 1)
    assert_not prompt.valid?
    assert_includes prompt.errors[:body], "can't be blank"
  end

  test "should limit body to 1000 characters" do
    prompt = @prompt_set.prompts.new(role: "system", body: "a" * 1001, position: 1)
    assert_not prompt.valid?
    assert_includes prompt.errors[:body], "is too long (maximum is 1000 characters)"
  end

  test "should require position" do
    prompt = @prompt_set.prompts.new(role: "system", body: "Hello", position: nil)
    assert_not prompt.valid?
    assert_includes prompt.errors[:position], "can't be blank"
  end

  test "render should replace variables" do
    prompt = @prompt_set.prompts.new(
      role: "user",
      body: "Goal: {{goal}}, Context: {{context}}, Due: {{due_date}}, Start: {{start_date}}",
      position: 1,
    )
    result = prompt.render(
      goal: "Build app",
      context: "Mobile first",
      due_date: "2026-04-15",
      start_date: "2026-04-01",
    )
    assert_equal "Goal: Build app, Context: Mobile first, Due: 2026-04-15, Start: 2026-04-01", result
  end

  test "render should handle empty variables" do
    prompt = @prompt_set.prompts.new(
      role: "user",
      body: "Goal: {{goal}}, Context: {{context}}",
      position: 1,
    )
    result = prompt.render(goal: "Build app", context: "")
    assert_equal "Goal: Build app, Context: ", result
  end

  test "render should handle nil variables" do
    prompt = @prompt_set.prompts.new(
      role: "user",
      body: "Goal: {{goal}}, Context: {{context}}",
      position: 1,
    )
    result = prompt.render(goal: "Build app", context: nil)
    assert_equal "Goal: Build app, Context: ", result
  end

  test "should require unique position within prompt_set" do
    @prompt_set.prompts.create!(role: "system", body: "First", position: 1)
    duplicate = @prompt_set.prompts.new(role: "user", body: "Second", position: 1)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end

  test "should allow same position across different prompt_sets" do
    other_set = PromptSet.create!(name: "Other Set")
    @prompt_set.prompts.create!(role: "system", body: "First", position: 1)
    other_prompt = other_set.prompts.new(role: "system", body: "Also First", position: 1)
    assert other_prompt.valid?
  end

  test "render should replace variables with string keys" do
    prompt = @prompt_set.prompts.new(
      role: "user",
      body: "Goal: {{goal}}, Context: {{context}}",
      position: 1,
    )
    result = prompt.render("goal" => "Build app", "context" => "Mobile first")
    assert_equal "Goal: Build app, Context: Mobile first", result
  end

  test "render should leave unknown variables as-is" do
    prompt = @prompt_set.prompts.new(
      role: "user",
      body: "Goal: {{goal}}, Unknown: {{unknown}}",
      position: 1,
    )
    result = prompt.render(goal: "Build app")
    assert_equal "Goal: Build app, Unknown: {{unknown}}", result
  end
end
