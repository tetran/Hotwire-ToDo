require "test_helper"

class DeactivatedUserTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  TEST_EMAILS = %w[subject@example.com performer@example.com].freeze

  setup do
    @user = User.create!(email: "subject@example.com", password: "password123")
    @performer = User.create!(email: "performer@example.com", password: "password123")
  end

  teardown do
    test_user_ids = User.where(email: TEST_EMAILS).pluck(:id)
    project_ids = Project.where(owner_id: test_user_ids).pluck(:id)

    DeactivatedUser.where(user_id: test_user_ids).delete_all
    DeactivatedUser.where(deactivated_by_id: test_user_ids).update_all(deactivated_by_id: nil)
    Event.where(user_id: test_user_ids).delete_all
    ProjectMember.where(user_id: test_user_ids).delete_all
    ProjectMember.where(project_id: project_ids).delete_all
    Project.where(id: project_ids).delete_all
    User.where(id: test_user_ids).delete_all
  end

  test "valid with required attributes" do
    record = DeactivatedUser.new(
      user: @user,
      original_email: "before@example.com",
      deactivated_at: Time.current,
    )
    assert record.valid?
  end

  test "requires original_email" do
    record = DeactivatedUser.new(user: @user, deactivated_at: Time.current)
    assert_not record.valid?
    assert_includes record.errors.attribute_names, :original_email
  end

  test "requires deactivated_at" do
    record = DeactivatedUser.new(user: @user, original_email: "x@example.com")
    assert_not record.valid?
    assert_includes record.errors.attribute_names, :deactivated_at
  end

  test "rejects invalid email format for original_email" do
    record = DeactivatedUser.new(
      user: @user,
      original_email: "not-an-email",
      deactivated_at: Time.current,
    )
    assert_not record.valid?
    assert_includes record.errors.attribute_names, :original_email
  end

  test "limits reason length to 500" do
    record = DeactivatedUser.new(
      user: @user,
      original_email: "x@example.com",
      deactivated_at: Time.current,
      reason: "a" * 501,
    )
    assert_not record.valid?
    assert_includes record.errors.attribute_names, :reason
  end

  test "reason is optional" do
    record = DeactivatedUser.new(
      user: @user,
      original_email: "x@example.com",
      deactivated_at: Time.current,
      reason: nil,
    )
    assert record.valid?
  end

  test "belongs_to user" do
    record = DeactivatedUser.create!(
      user: @user,
      original_email: "x@example.com",
      deactivated_at: Time.current,
    )
    assert_equal @user.id, record.reload.user_id
  end

  test "belongs_to deactivated_by is optional" do
    record = DeactivatedUser.create!(
      user: @user,
      original_email: "x@example.com",
      deactivated_at: Time.current,
      deactivated_by: nil,
    )
    assert_nil record.deactivated_by
  end

  test "tracks deactivated_by performer" do
    record = DeactivatedUser.create!(
      user: @user,
      original_email: "x@example.com",
      deactivated_at: Time.current,
      deactivated_by: @performer,
    )
    assert_equal @performer.id, record.deactivated_by_id
  end

  test "user.deactivation has dependent: :destroy (Rails-level cascade)" do
    reflection = User.reflect_on_association(:deactivation)
    assert_equal :destroy, reflection.options[:dependent]
  end
end
