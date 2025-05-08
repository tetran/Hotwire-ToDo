module TurboStreamActionsHelper
  def show_remote_modal(&block)
    turbo_stream_action_tag(
      :show_remote_modal,
      template: @view_context.capture(&block)
    )
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
