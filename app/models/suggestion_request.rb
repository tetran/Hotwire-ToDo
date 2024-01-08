class SuggestionRequest < ApplicationRecord
  attr_accessor :raw_request_hash

  belongs_to :project
  belongs_to :requested_by, class_name: "User"
  has_one :response, dependent: :destroy, class_name: "SuggestionResponse", inverse_of: :suggestion_request

  before_save :set_raw_request

  validates :goal, presence: true, length: { maximum: 100 }

  def openai_params = raw_request_hash || JSON.parse(raw_request)

  private

    def set_raw_request
      @raw_request_hash = {
        model: "gpt-3.5-turbo-1106",
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: "You are a professional strategy consultant who helps clients achieve their goals." },
          { role: "system", content: "You can speak any language, and when you are asked a question, you respond in the same language as the client." },
          { role: "user", content: instruction }
        ],
        temperature: 0.7
      }
      self.raw_request = raw_request_hash.to_json
    end

    def instruction
      restriction = "* Responses MUST be in JSON with the format below.\n"
      restriction += <<~FORMAT.strip
      Format: {"tasks":[{"name":"{name (Up to 100 characters)}","description":"{Why and how to do it (Even a beginner can understand. Up to 500 characters)}","due_date":"{yyyy/mm/dd}"}]}
      FORMAT
      restriction += "* Responses MUST be in the same language as the client's.\n"
      restriction += "* Tasks SHOULD be specific and able to be judged yes/no as to whether they are completed or not.\n"
      restriction += "* A realistic due date SHOULD be set for each task.\n"
      restriction += "* If the overall due date specified by the client is not realistic, ignore it and suggest a realistic due date."
      restriction += "* Other contexts to be considered: #{context}\n" if context.present?

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
