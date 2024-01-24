# frozen_string_literal: true

module ProjectDependent
  extend ActiveSupport::Concern

  included do
    before_action :set_project
  end

  private

    def set_project
      @project = current_user.projects.find(params[:project_id])
    end
end
