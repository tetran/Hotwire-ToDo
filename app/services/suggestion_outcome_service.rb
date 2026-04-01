class SuggestionOutcomeService
  def self.record_adoption(suggestion_response:, adopted_count:)
    existing = suggestion_response.suggestion_outcome
    return existing if existing

    total_suggested = suggestion_response.suggested_tasks.count
    suggestion_response.create_suggestion_outcome!(
      total_suggested: total_suggested,
      total_adopted: [adopted_count, total_suggested].min,
    )
  rescue ActiveRecord::RecordNotUnique
    SuggestionOutcome.find_by!(suggestion_response_id: suggestion_response.id)
  end

  def self.record_abandonment(suggestion_response:)
    existing = suggestion_response.suggestion_outcome
    return existing if existing

    suggestion_response.create_suggestion_outcome!(
      total_suggested: suggestion_response.suggested_tasks.count,
      total_adopted: 0,
    )
  rescue ActiveRecord::RecordNotUnique
    SuggestionOutcome.find_by!(suggestion_response_id: suggestion_response.id)
  end
end
