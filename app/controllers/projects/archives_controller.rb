module Projects
  class ArchivesController < ApplicationController
    include ProjectDependent

    def create
      @project.archive!
      redirect_to project_url(session[:current_project_id] || current_user.inbox_project.id),
                  success: t("controllers.projects/archives.create.success", name: @project.name)
    end

    def destroy
      @project.unarchive!
      redirect_to project_url(@project),
                  success: t("controllers.projects/archives.destroy.success", name: @project.name)
    end
  end
end
