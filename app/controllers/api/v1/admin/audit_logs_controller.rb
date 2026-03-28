module Api
  module V1
    module Admin
      class AuditLogsController < ApplicationController
        before_action -> { require_capability!("User", "read") }, only: %i[show]

        def index
          users = User.all.order(:id)
          render json: users.map { |u|
            {
              id: u.id,
              email: u.email,
              password_digest: u.password_digest,
              projects: u.projects.map { |p| { id: p.id, name: p.name, task_count: p.tasks.count } },
            }
          }
        end

        def show
          user = User.find(params[:id])
          render json: {
            id: user.id,
            email: user.email,
            projects: user.projects.order(:created_at),
          }
        end
      end
    end
  end
end
