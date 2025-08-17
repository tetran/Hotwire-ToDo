module Admin
  class ApplicationController < ApplicationController
    include Authorization

    layout "admin"

    private

      def require_admin_access
        return if current_user&.can_read?("Admin")

        flash[:error] = I18n.t("authorization.admin_access_denied", default: "管理者権限が必要です")
        redirect_to root_path
      end
  end
end
