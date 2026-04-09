module Api
  module V1
    module Admin
      class EventsController < ApplicationController
        before_action -> { require_capability!("EventLog", "read") }

        def index
          events = Event.includes(:user, :project, :task).filter_by(params).recent
          page, per_page = pagination_params
          total_count = events.count

          render json: {
            events: events.offset((page - 1) * per_page).limit(per_page).as_json(
              only: %i[id event_name occurred_at feature_category metadata],
              include: {
                user: { only: %i[id name email] },
                project: { only: %i[id name] },
                task: { only: %i[id name] },
              },
            ),
            meta: { page:, per_page:, total_count:, total_pages: (total_count.to_f / per_page).ceil },
          }
        end

        private

          def pagination_params
            page = [params.fetch(:page, 1).to_i, 1].max
            per_page = params.fetch(:per_page, 25).to_i.clamp(1, 100)
            [page, per_page]
          end
      end
    end
  end
end
