module Tasks
  class SearchesController < ApplicationController
    def index
      @query = params[:q].to_s.strip
      @show_completed = params[:completed] == "true"

      @tasks = search_tasks if @query.present?
    end

    private

      def search_tasks
        scope = current_user.tasks.includes(:project)
        scope = @show_completed ? scope.completed : scope.uncompleted
        scope
          .left_joins(:rich_text_description)
          .where("tasks.name ILIKE :q OR action_text_rich_texts.body ILIKE :q", q: "%#{@query}%")
          .order(updated_at: :desc)
          .limit(20)
      end
  end
end
