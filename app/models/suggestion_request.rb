class SuggestionRequest < ApplicationRecord
  belongs_to :suggestion_session
  belongs_to :llm_model, optional: true
  belongs_to :suggestion_config_entry, optional: true
  has_one :response, dependent: :destroy, class_name: "SuggestionResponse", inverse_of: :suggestion_request

  def request_params
    JSON.parse(raw_request).with_indifferent_access
  end
end
