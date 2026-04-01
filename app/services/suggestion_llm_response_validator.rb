class SuggestionLlmResponseValidator
  REQUIRED_TASK_KEYS = %w[name description due_date].freeze
  SORTED_REQUIRED_TASK_KEYS = REQUIRED_TASK_KEYS.sort.freeze

  def validate(content)
    parsed = parse_response_content(content)
    return [false, "invalid JSON"] unless parsed

    validation_error = validate_tasks_payload(parsed)
    return [false, validation_error] if validation_error

    [true, nil]
  end

  private

    def parse_response_content(content)
      JSON.parse(content)
    rescue JSON::ParserError, TypeError
      nil
    end

    def validate_tasks_payload(parsed)
      tasks = parsed["tasks"]
      return "tasks is not a non-empty array" unless tasks.is_a?(Array) && tasks.any?
      return "response includes unexpected top-level keys" unless parsed.keys == ["tasks"]
      return "tasks include unexpected keys" unless tasks_have_only_required_keys?(tasks)
      return "tasks missing required keys (#{REQUIRED_TASK_KEYS.join(', ')})" unless required_values_present?(tasks)

      nil
    end

    def tasks_have_only_required_keys?(tasks)
      tasks.all? do |task|
        task.is_a?(Hash) && task.keys.sort == SORTED_REQUIRED_TASK_KEYS
      end
    end

    def required_values_present?(tasks)
      tasks.all? { |task| REQUIRED_TASK_KEYS.all? { |key| task[key].present? } }
    end
end
