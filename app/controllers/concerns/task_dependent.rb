# frozen_string_literal: true

module TaskDependent
  extend ActiveSupport::Concern

  included do
    before_action :set_task
  end

  private

    def set_task
      @task = current_user.tasks.find(params[:task_id])
    end
end
