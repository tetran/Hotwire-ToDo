class SuggestionLlmService
  MAX_ATTEMPTS = 3
  TEMPERATURES = [0.7, 0.3, 0.3].freeze
  FINAL_ATTEMPT_PROMPT = <<~PROMPT.squish.freeze
    IMPORTANT: Your response MUST be valid JSON only. No text before or after.
    Format: {"tasks":[{"name":"...","description":"...","due_date":"yyyy/mm/dd"}]}
  PROMPT
  JSON_OUTPUT_SCHEMA_NAME = "emit_tasks_json".freeze
  JSON_OUTPUT_SCHEMA = {
    type: "object",
    additionalProperties: false,
    properties: {
      tasks: {
        type: "array",
        minItems: 1,
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            name: { type: "string" },
            description: { type: "string" },
            due_date: { type: "string" },
          },
          required: SuggestionLlmResponseValidator::REQUIRED_TASK_KEYS,
        },
      },
    },
    required: ["tasks"],
  }.freeze

  def initialize(entry:, session:, variables:)
    @entry = entry
    @session = session
    @variables = variables
    @client = LlmClientFactory.create_client_from_model(entry.llm_model)
    @response_validator = SuggestionLlmResponseValidator.new
  end

  def call
    MAX_ATTEMPTS.times do |attempt|
      create_request(attempt)
      response, should_retry = attempt_with_instrumentation(attempt)
      return response if response
      return nil unless should_retry
    end

    log_retry_exhausted
    nil
  end

  private

    attr_reader :entry, :session, :variables, :client, :response_validator

    def build_messages(attempt)
      messages = entry.prompt_set.prompts.order(:position).map do |prompt|
        { role: prompt.role, content: prompt.render(variables) }
      end

      if attempt == MAX_ATTEMPTS - 1
        messages << {
          role: "user",
          content: FINAL_ATTEMPT_PROMPT,
        }
      end

      messages
    end

    def create_request(attempt)
      request_payload = build_request_payload(attempt)
      SuggestionRequest.create!(
        suggestion_session: session,
        suggestion_config_entry: entry,
        raw_request: request_payload.to_json,
      )
    end

    def attempt_with_instrumentation(attempt)
      payload = instrument_payload(attempt)
      response = nil
      should_retry = false
      ActiveSupport::Notifications.instrument "chat.llm", payload do
        raw_response = client.chat(**build_request_payload(attempt))
        response, should_retry = process_raw_response(raw_response, attempt, payload)
      rescue LlmClient::ApiError => e
        payload[:success] = false
        log_api_error(attempt: attempt, error: e)
      end
      [response, should_retry]
    end

    def process_raw_response(raw_response, attempt, payload)
      valid, reason = validate_response(raw_response[:content])
      if valid
        payload[:success] = true
        [raw_response, false]
      else
        payload[:success] = false
        log_retry_failure(attempt: attempt, reason: reason, content: raw_response[:content])
        [nil, true]
      end
    end

    def build_request_payload(attempt)
      {
        messages: build_messages(attempt),
        model: entry.llm_model.name,
        temperature: TEMPERATURES[attempt],
      }.merge(client.json_output_options(**structured_output_options))
    end

    def structured_output_options
      {
        structured_output: {
          enabled: true,
          schema_name: JSON_OUTPUT_SCHEMA_NAME,
          schema: JSON_OUTPUT_SCHEMA,
          strict: true,
        },
        json_only: true,
      }
    end

    def validate_response(content)
      response_validator.validate(content)
    end

    def instrument_payload(attempt)
      {
        session_id: session.id,
        provider: entry.llm_model.llm_provider.name,
        model: entry.llm_model.name,
        prompt_set: entry.prompt_set.name,
        config_entry_id: entry.id,
        attempt: attempt + 1,
      }
    end

    def log_retry_failure(attempt:, reason:, content:)
      return unless Rails.env.development?

      Rails.logger.debug do
        "[SuggestionLlmService] invalid response, retrying " \
          "(session_id=#{session.id}, attempt=#{attempt + 1}/#{MAX_ATTEMPTS}, " \
          "reason=#{reason}, content=#{truncated_content(content)})"
      end
    end

    def log_retry_exhausted
      return unless Rails.env.development?

      Rails.logger.debug do
        "[SuggestionLlmService] retries exhausted (session_id=#{session.id}, max_attempts=#{MAX_ATTEMPTS})"
      end
    end

    def log_api_error(attempt:, error:)
      return unless Rails.env.development?

      Rails.logger.debug do
        "[SuggestionLlmService] api error, aborting " \
          "(session_id=#{session.id}, attempt=#{attempt + 1}/#{MAX_ATTEMPTS}, " \
          "error_class=#{error.class}, status=#{error.status_code}, message=#{error.message})"
      end
    end

    def truncated_content(content)
      content.to_s.tr("\n", " ")[0, 500]
    end
end
