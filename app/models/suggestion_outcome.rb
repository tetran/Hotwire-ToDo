class SuggestionOutcome < ApplicationRecord
  HIGH_ACCEPTANCE_THRESHOLD = 80.0

  belongs_to :suggestion_response

  validates :total_suggested, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_adopted, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :adopted_not_exceeding_suggested

  before_save :calculate_acceptance

  private

    def adopted_not_exceeding_suggested
      return if total_adopted.nil? || total_suggested.nil?

      return unless total_adopted > total_suggested

      errors.add(:total_adopted, "cannot exceed total_suggested")
    end

    def calculate_acceptance
      self.acceptance_rate = total_suggested.positive? ? (total_adopted.to_f / total_suggested * 100).round(2) : 0.0
      self.high_acceptance = acceptance_rate >= HIGH_ACCEPTANCE_THRESHOLD
    end
end
