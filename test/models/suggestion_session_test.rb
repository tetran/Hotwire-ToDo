require "test_helper"

class SuggestionSessionTest < ActiveSupport::TestCase
  setup do
    @session = suggestion_sessions(:one)
    @user = users(:regular_user)
    @project = projects(:one)
    # Clear recent sessions to avoid rate limit interference from fixtures
    SuggestedTask.delete_all
    SuggestionResponse.delete_all
    SuggestionRequest.delete_all
    SuggestionSession.where("created_at > ?", 1.minute.ago).delete_all
  end

  # === Associations ===

  test "belongs to project" do
    assert_equal @project, @session.project
  end

  test "belongs to requested_by" do
    assert_equal @user, @session.requested_by
  end

  test "has many suggestion_requests" do
    assert_respond_to @session, :suggestion_requests
  end

  # === Validations ===

  test "valid with required attributes" do
    session = SuggestionSession.new(
      goal: "Learn Ruby",
      project: @project,
      requested_by: @user,
    )
    assert session.valid?
  end

  test "invalid without goal" do
    session = SuggestionSession.new(project: @project, requested_by: @user)
    assert_not session.valid?
    assert session.errors.added?(:goal, :blank)
  end

  test "invalid with goal exceeding 100 characters" do
    session = SuggestionSession.new(
      goal: "a" * 101,
      project: @project,
      requested_by: @user,
    )
    assert_not session.valid?
    assert session.errors[:goal].any? { |e| e.include?("100") }
  end

  test "valid with goal at exactly 100 characters" do
    session = SuggestionSession.new(
      goal: "a" * 100,
      project: @project,
      requested_by: @user,
    )
    assert session.valid?
  end

  # === Rate Limiting ===

  test "allows up to 2 sessions per minute for same user" do
    SuggestionSession.create!(
      goal: "First goal",
      project: @project,
      requested_by: @user,
    )
    session2 = SuggestionSession.new(
      goal: "Second goal",
      project: @project,
      requested_by: @user,
    )
    assert session2.valid?
  end

  test "rejects more than 2 sessions per minute for same user" do
    2.times do |i|
      SuggestionSession.create!(
        goal: "Goal #{i}",
        project: @project,
        requested_by: @user,
      )
    end

    session3 = SuggestionSession.new(
      goal: "Third goal",
      project: @project,
      requested_by: @user,
    )
    assert_not session3.valid?
    assert_includes session3.errors[:base], I18n.t("activerecord.errors.messages.too_many_requests")
  end

  test "allows sessions from different users independently" do
    other_user = users(:admin_user)
    2.times do |i|
      SuggestionSession.create!(
        goal: "Goal #{i}",
        project: @project,
        requested_by: @user,
      )
    end

    session = SuggestionSession.new(
      goal: "Other user goal",
      project: @project,
      requested_by: other_user,
    )
    assert session.valid?
  end
end
