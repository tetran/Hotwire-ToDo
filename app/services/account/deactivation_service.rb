module Account
  # Service for user deactivation and reactivation.
  # Sentinel email format: deactivated+{user_id}+{16 hex}@deactivated.invalid (RFC 2606 invalid TLD).
  class DeactivationService
    def self.call(user:, performer:, reason: nil, self_deactivated: false)
      original_email = user.email
      ActiveRecord::Base.transaction do
        DeactivatedUser.create!(
          user: user,
          original_email: original_email,
          reason: reason,
          deactivated_by: performer,
          deactivated_at: Time.current,
        )
        user.update_column(:email, sentinel_email_for(user))
        Events::Recorder.record(
          event_name: "user_deactivated",
          user: performer,
          metadata: {
            target_user_id: user.id,
            self_deactivated: self_deactivated,
            original_email: original_email,
          },
        )
      end
    end

    # Concurrent reactivation by two admins is protected with FOR UPDATE on the
    # `deactivated_users` row. The second tx waits for the first to commit, then
    # `lock.find_by` returns nil (row destroyed) → RecordNotFound surfaces as 404.
    # Without this, `user.deactivation.original_email` reload could raise NoMethodError.
    def self.reactivate(user:, performer:, new_email: nil)
      ActiveRecord::Base.transaction do
        deactivation = DeactivatedUser.lock.find_by(user_id: user.id)
        raise ActiveRecord::RecordNotFound, "User is not deactivated" unless deactivation

        target_email = new_email.presence || deactivation.original_email
        user.update!(email: target_email)
        deactivation.destroy!
        Events::Recorder.record(
          event_name: "user_reactivated",
          user: performer,
          metadata: {
            target_user_id: user.id,
            restored_email: target_email,
          },
        )
      end
    end

    def self.sentinel_email_for(user)
      "deactivated+#{user.id}+#{SecureRandom.hex(8)}@deactivated.invalid"
    end
  end
end
