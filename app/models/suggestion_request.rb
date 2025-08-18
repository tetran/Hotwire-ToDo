class SuggestionRequest < ApplicationRecord
  attr_accessor :raw_request_hash

  # 同じユーザー(requested_by)からのリクエストは1分間に2回まで
  MAX_REQUEST_PER_MINUTE = 2

  belongs_to :project
  belongs_to :requested_by, class_name: "User"
  belongs_to :llm_model
  has_one :response, dependent: :destroy, class_name: "SuggestionResponse", inverse_of: :suggestion_request

  before_save :set_raw_request

  validate :too_many_requests
  validates :goal, presence: true, length: { maximum: 100 }

  def openai_params = raw_request_hash || JSON.parse(raw_request)

  private

    def too_many_requests
      errors.add(:base, :too_many_requests) if SuggestionRequest.where(requested_by: requested_by).where(
        "created_at > ?", 1.minute.ago
      ).count >= MAX_REQUEST_PER_MINUTE
    end

    def set_raw_request
      @raw_request_hash = {
        model: "gpt-4.1-mini",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: "You are a professional and friendly strategy consultant who helps clients achieve their goals.",
          },
          {
            role: "system",
            content: "As you can speak any language and are very kind, you respond in the same language as the client.",
          },
          { role: "user", content: instruction },
        ],
        temperature: 0.7,
      }
      self.raw_request = raw_request_hash.to_json
    end

    def instruction
      restriction = <<~RESTRICTION.strip
        * Responses MUST be in JSON with the format: {"tasks":[{"name":"{name (Up to 100 characters)}","description":"{What, why and how(Even a beginner can understand. Up to 200 characters)}","due_date":"{yyyy/mm/dd}"}]}
        * Responses MUST be in the same language as the client's.
        * Tasks MUST be specific and able to be judged yes/no as to whether they are completed or not.
        * If the goal contains emoji, task names SHOULD contain emojis too.
        * A realistic due date SHOULD be set for each task.
        * If the overall due date (#{due_date}) is not realistic, ignore it and suggest a realistic due date.
        * There MUST be at least one task with a due date on the last day
      RESTRICTION
      restriction << "\n* Other contexts to be considered: #{context}" if context.present?

      <<~INSTRUCTION.strip
        Please break down what is needed to accomplish the goal below into tasks (Up to 10) with fine granularity.
        ### Client's Goal
        * Goal: #{goal}
        * Start date: #{start_date}
        * Overall due date: #{due_date}
        ### Restriction
        #{restriction}
      INSTRUCTION
    end
end
