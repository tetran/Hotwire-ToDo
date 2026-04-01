class PromptSet < ApplicationRecord
  has_many :prompts, -> { order(:position) }, dependent: :destroy, inverse_of: :prompt_set
  has_many :suggestion_config_entries, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  accepts_nested_attributes_for :prompts, allow_destroy: true

  validate :cannot_deactivate_when_in_use, if: -> { active_changed?(from: true, to: false) }

  private

    def cannot_deactivate_when_in_use
      return unless suggestion_config_entries.joins(:suggestion_config).exists?(suggestion_configs: { active: true })

      errors.add(:active, "cannot be deactivated while used in an active suggestion config")
    end
end
