module Events
  class Recorder
    def self.record(event_name:, user:, project: nil, task: nil, metadata: {})
      feature_category = Event::FEATURE_CATEGORIES[event_name]

      Event.create!(
        event_name: event_name,
        occurred_at: Time.current,
        user: user,
        project: project,
        task: task,
        feature_category: feature_category,
        metadata: metadata,
      )
    rescue StandardError => e
      Rails.logger.error("Event recording failed: #{e.message}")
      nil
    end
  end
end
