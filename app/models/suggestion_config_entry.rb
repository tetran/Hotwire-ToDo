class SuggestionConfigEntry < ApplicationRecord
  belongs_to :suggestion_config
  belongs_to :llm_model
  belongs_to :prompt_set

  validates :weight, presence: true,
                     numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validates :llm_model_id, uniqueness: { scope: %i[suggestion_config_id prompt_set_id] }
end
