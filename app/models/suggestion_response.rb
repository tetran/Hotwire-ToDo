class SuggestionResponse < ApplicationRecord
  belongs_to :suggestion_request
  has_many :suggested_tasks, dependent: :destroy
  has_one :suggestion_outcome, dependent: :destroy

  def self.batch_create(request, normalized_response)
    content = normalized_response[:content]
    usage = normalized_response[:usage] || {}
    suggested_tasks = JSON.parse(content)["tasks"]

    transaction do
      resp = create!(
        suggestion_request: request,
        raw_response: normalized_response.to_json,
        completion_tokens: usage[:output_tokens] || 0,
        prompt_tokens: usage[:input_tokens] || 0,
      )
      SuggestedTask.insert_all!(suggested_tasks.map { |t| t.merge(suggestion_response_id: resp.id) })
      resp
    end
  end
end
