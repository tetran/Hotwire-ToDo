module Projects
  class ArchivesController < ApplicationController
    include ProjectDependent

    def create
      @project.archive!
      redirect_to project_url(session[:current_project_id] || current_user.inbox_project.id), success: "Project \"#{@project.name}\" was archived."
    end

    def destroy
      @project.unarchive!
      redirect_to project_url(@project), success: "Project \"#{@project.name}\" was unarchived."
    end
  end
end
