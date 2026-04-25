module Account
  # Pre-Fork skeleton. Phase 1B fills in the transaction bodies.
  # Contract:
  #   - call(user:, performer:, reason: nil, self_deactivated: false) - deactivates a user
  #   - reactivate(user:, performer:, new_email: nil)                  - restores a user
  # Both methods record an `events` row via Events::Recorder (event names
  # `user_deactivated` / `user_reactivated`, category `account_lifecycle`).
  # Sentinel email format: deactivated+{user_id}+{16 hex}@deactivated.invalid (RFC 2606 invalid TLD).
  class DeactivationService
    # rubocop:disable Lint/UnusedMethodArgument
    def self.call(user:, performer:, reason: nil, self_deactivated: false)
      ActiveRecord::Base.transaction do
        # Phase 1B implements:
        # 1. DeactivatedUser.create!(user:, original_email: user.email, reason:,
        #      deactivated_by: performer, deactivated_at: Time.current)
        # 2. user.update_column(:email, sentinel_email_for(user))
        # 3. Events::Recorder.record(event_name: "user_deactivated", user: performer,
        #      metadata: { target_user_id: user.id, self_deactivated:,
        #                  original_email: user.deactivation.original_email })
      end
    end

    def self.reactivate(user:, performer:, new_email: nil)
      ActiveRecord::Base.transaction do
        # Phase 1B implements:
        # target_email = new_email.presence || user.deactivation.original_email
        # 1. user.update!(email: target_email)  # uniqueness validation surfaces conflict
        # 2. user.deactivation.destroy!
        # 3. Events::Recorder.record(event_name: "user_reactivated", user: performer,
        #      metadata: { target_user_id: user.id, restored_email: target_email })
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def self.sentinel_email_for(user)
      "deactivated+#{user.id}+#{SecureRandom.hex(8)}@deactivated.invalid"
    end
  end
end
