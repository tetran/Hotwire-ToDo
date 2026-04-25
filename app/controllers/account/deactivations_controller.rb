module Account
  # Pre-Fork stub. Phase 1B replaces with the real self-deactivation flow
  # (password_challenge form + reason textarea, transactional deactivation,
  # reset_session, redirect to login).
  class DeactivationsController < ApplicationController
    def new
      head :not_implemented
    end

    def create
      head :not_implemented
    end
  end
end
