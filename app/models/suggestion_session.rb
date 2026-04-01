class SuggestionSession < ApplicationRecord
  MAX_SESSIONS_PER_MINUTE = 2

  belongs_to :project
  belongs_to :requested_by, class_name: "User"
  has_many :suggestion_requests, dependent: :destroy

  validates :goal, presence: true, length: { maximum: 100 }

  validate :too_many_requests

  private

    def too_many_requests
      return unless requested_by

      count = SuggestionSession.where(requested_by: requested_by)
                               .where("created_at > ?", 1.minute.ago)
                               .count
      errors.add(:base, :too_many_requests) if count >= MAX_SESSIONS_PER_MINUTE
    end
end
