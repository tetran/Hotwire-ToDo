class LlmModel < ApplicationRecord
  belongs_to :llm_provider
  has_many :suggestion_requests, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :llm_provider_id }
  validates :display_name, presence: true

  scope :active, -> { where(active: true) }
  scope :default, -> { where(default_model: true) }

  before_save :ensure_single_default

  def full_name
    "#{llm_provider.name} - #{display_name}"
  end

  private

    def ensure_single_default
      return unless default_model?

      LlmModel.where(llm_provider: llm_provider)
              .where.not(id: id)
              .update_all(default_model: false)
    end
end
