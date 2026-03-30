class Prompt < ApplicationRecord
  ROLES = %w[system user].freeze
  VARIABLES = %w[goal context due_date start_date].freeze

  belongs_to :prompt_set

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :body, presence: true, length: { maximum: 1000 }
  validates :position, presence: true, uniqueness: { scope: :prompt_set_id }

  def render(variables = {})
    vars = variables.symbolize_keys
    VARIABLES.reduce(body.dup) do |result, var|
      result.gsub("{{#{var}}}", vars[var.to_sym].to_s)
    end
  end
end
