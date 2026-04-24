class LlmModel < ApplicationRecord
  belongs_to :llm_provider
  has_many :suggestion_requests, dependent: :restrict_with_error
  has_many :suggestion_config_entries, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :llm_provider_id }
  validates :display_name, presence: true

  scope :active, -> { where(active: true) }

  validate :cannot_deactivate_when_in_use, if: -> { active_changed?(from: true, to: false) }

  def full_name
    "#{llm_provider.name} - #{display_name}"
  end

  private

    def cannot_deactivate_when_in_use
      return unless suggestion_config_entries.joins(:suggestion_config).exists?(suggestion_configs: { active: true })

      errors.add(:active, "cannot be deactivated while used in an active suggestion config")
    end
end
