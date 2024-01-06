module Projects
  class ArchivesController < ApplicationController
    def create
      project = current_user.projects.unarchived.find(params[:project_id])
      project.archive!
      redirect_to project_url(session[:current_project_id] || current_user.inbox_project.id), success: "Project \"#{project.name}\" was archived."
    end

    def destroy
      project = current_user.projects.archived.find(params[:project_id])
      project.unarchive!
      redirect_to project_url(project.id), success: "Project \"#{project.name}\" was unarchived."
    end
  end
end
