module Tasks
  class CommentsController < ApplicationController
    include TaskDependent

    def new
      @comment = @task.comments.build
    end

    def create
      @comment = @task.comments.build(comment_params.merge(user: current_user))

      respond_to do |format|
        if @comment.save
          format.html { redirect_to @task, notice: "Comment was successfully created." }
          format.turbo_stream
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      @comment = @task.comments.find(params[:id])
    end

    def update
      @comment = @task.comments.find(params[:id])

      respond_to do |format|
        if @comment.editable_by?(current_user) && @comment.update(comment_params)
          format.html { redirect_to @task, notice: "Comment was successfully updated." }
          format.turbo_stream
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @comment = @task.comments.find(params[:id])

      respond_to do |format|
        if @comment.editable_by?(current_user) && @comment.destroy
          format.html { redirect_to @task, notice: "Comment was successfully destroyed." }
          format.turbo_stream
        else
          format.html { redirect_to @task, alert: "Comment could not be destroyed." }
        end
      end
    end

    private

      def comment_params
        params.require(:comment).permit(:content)
      end
  end
end
