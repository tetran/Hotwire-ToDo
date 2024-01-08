class SuggestionResponse < ApplicationRecord
  belongs_to :suggestion_request
  has_many :suggested_tasks, dependent: :destroy

  def self.batch_create(request, raw_response)
    suggested_tasks = JSON.parse(raw_response.dig("choices", 0, "message", "content"))["tasks"]
    usage = raw_response["usage"]
    transaction do
      resp = create!(
        suggestion_request: request,
        raw_response: raw_response.to_json,
        completion_tokens: usage["completion_tokens"],
        prompt_tokens: usage["prompt_tokens"]
      )
      SuggestedTask.insert_all!(suggested_tasks.map { |t| t.merge(suggestion_response_id: resp.id) })
      resp
    end
  end
end
