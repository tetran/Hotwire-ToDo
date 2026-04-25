require "test_helper"

module Account
  class DeactivationServiceTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(email: "target@example.com", password: "password123")
      @performer = User.create!(email: "admin@service-test.com", password: "password123")
    end

    def teardown # rubocop:disable Metrics/AbcSize
      ids = [@user.id, @performer.id]
      Event.where(user_id: ids).delete_all
      DeactivatedUser.where(user_id: ids).delete_all
      DeactivatedUser.where(deactivated_by_id: ids).update_all(deactivated_by_id: nil)
      project_ids = Project.where(owner_id: ids).pluck(:id)
      ProjectMember.where(project_id: project_ids).delete_all
      ProjectMember.where(user_id: ids).delete_all
      Project.where(id: project_ids).delete_all
      User.where(id: ids).delete_all
    end

    # --- call ---

    test "call: does not destroy the user record" do
      assert_no_difference("User.count") do
        Account::DeactivationService.call(user: @user, performer: @performer)
      end
    end

    test "call: creates a DeactivatedUser record" do
      assert_difference("DeactivatedUser.count", 1) do
        Account::DeactivationService.call(user: @user, performer: @performer)
      end
    end

    test "call: preserves original_email in DeactivatedUser" do
      original_email = @user.email
      Account::DeactivationService.call(user: @user, performer: @performer)

      assert_equal original_email, @user.reload.deactivation.original_email
    end

    test "call: sentinel email format matches deactivated+{user_id}+{16hex}@deactivated.invalid" do
      Account::DeactivationService.call(user: @user, performer: @performer)
      sentinel = @user.reload.email

      assert_match(/\Adeactivated\+#{@user.id}\+[0-9a-f]{16}@deactivated\.invalid\z/, sentinel)
    end

    test "call: sentinel email is accepted by URI::MailTo::EMAIL_REGEXP" do
      sentinel = Account::DeactivationService.sentinel_email_for(@user)
      assert_match URI::MailTo::EMAIL_REGEXP, sentinel
    end

    test "call: records user_deactivated event with account_lifecycle category" do
      assert_difference("Event.count", 1) do
        Account::DeactivationService.call(user: @user, performer: @performer)
      end

      event = Event.last
      assert_equal "user_deactivated", event.event_name
      assert_equal "account_lifecycle", event.feature_category
    end

    test "call: event metadata includes target_user_id and self_deactivated" do
      Account::DeactivationService.call(user: @user, performer: @performer, self_deactivated: true)
      event = Event.last

      assert_equal @user.id, event.metadata["target_user_id"]
      assert_equal true, event.metadata["self_deactivated"]
    end

    test "call: event metadata includes original_email" do
      original_email = @user.email
      Account::DeactivationService.call(user: @user, performer: @performer)
      event = Event.last

      assert_equal original_email, event.metadata["original_email"]
    end

    test "call: saves reason in DeactivatedUser" do
      Account::DeactivationService.call(user: @user, performer: @performer, reason: "Testing reason")
      assert_equal "Testing reason", @user.reload.deactivation.reason
    end

    test "call: records deactivated_by performer" do
      Account::DeactivationService.call(user: @user, performer: @performer)
      assert_equal @performer.id, @user.reload.deactivation.deactivated_by_id
    end

    test "call: rolls back on error (transactional)" do
      original_email = @user.email
      # Force an error inside the transaction by making update_column raise
      DeactivatedUser.stubs(:create!).raises(ActiveRecord::RecordInvalid)

      assert_raises(ActiveRecord::RecordInvalid) do
        Account::DeactivationService.call(user: @user, performer: @performer)
      end

      assert_equal 0, DeactivatedUser.where(user: @user).count
      assert_equal original_email, @user.reload.email
    end

    # --- reactivate ---

    test "reactivate: restores original email when free" do
      original_email = @user.email
      Account::DeactivationService.call(user: @user, performer: @performer)
      Account::DeactivationService.reactivate(user: @user, performer: @performer)

      assert_equal original_email, @user.reload.email
    end

    test "reactivate: destroys DeactivatedUser record" do
      Account::DeactivationService.call(user: @user, performer: @performer)

      assert_difference("DeactivatedUser.count", -1) do
        Account::DeactivationService.reactivate(user: @user, performer: @performer)
      end
    end

    test "reactivate: raises RecordInvalid when target email is taken" do
      original_email = @user.email
      Account::DeactivationService.call(user: @user, performer: @performer)
      # Another user takes the original email
      User.create!(email: original_email, password: "password123")

      assert_raises(ActiveRecord::RecordInvalid) do
        Account::DeactivationService.reactivate(user: @user, performer: @performer)
      end
    end

    test "reactivate: uses new_email override when provided" do
      Account::DeactivationService.call(user: @user, performer: @performer)
      new_addr = "restored-custom@example.com"
      Account::DeactivationService.reactivate(user: @user, performer: @performer, new_email: new_addr)

      assert_equal new_addr, @user.reload.email
    end

    test "reactivate: records user_reactivated event with account_lifecycle category" do
      Account::DeactivationService.call(user: @user, performer: @performer)

      assert_difference("Event.count", 1) do
        Account::DeactivationService.reactivate(user: @user, performer: @performer)
      end

      event = Event.last
      assert_equal "user_reactivated", event.event_name
      assert_equal "account_lifecycle", event.feature_category
    end

    test "reactivate: event metadata includes target_user_id and restored_email" do
      original_email = @user.email
      Account::DeactivationService.call(user: @user, performer: @performer)
      Account::DeactivationService.reactivate(user: @user, performer: @performer)
      event = Event.last

      assert_equal @user.id, event.metadata["target_user_id"]
      assert_equal original_email, event.metadata["restored_email"]
    end

    # Regression: concurrent reactivation. If a second request enters reactivate
    # after the first has already destroyed the DeactivatedUser row, the user
    # has no associated deactivation. The service must surface this as
    # ActiveRecord::RecordNotFound (so the controller can map it to 422),
    # not crash with NoMethodError on nil.
    test "reactivate: raises RecordNotFound when user has no deactivation (concurrent path)" do
      Account::DeactivationService.call(user: @user, performer: @performer)
      @user.deactivation.destroy!
      @user.reload

      assert_raises(ActiveRecord::RecordNotFound) do
        Account::DeactivationService.reactivate(user: @user, performer: @performer)
      end
    end

    test "reactivate: does not record event when no deactivation exists" do
      Account::DeactivationService.call(user: @user, performer: @performer)
      @user.deactivation.destroy!
      @user.reload

      assert_no_difference("Event.count") do
        assert_raises(ActiveRecord::RecordNotFound) do
          Account::DeactivationService.reactivate(user: @user, performer: @performer)
        end
      end
    end
  end
end
