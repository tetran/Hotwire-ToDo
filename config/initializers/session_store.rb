if Rails.env.production?
  Rails.application.config.session_store :redis_store, servers: "#{ENV.fetch("REDIS_URL")}/0/session", expire_after: 90.minutes
else
  Rails.application.config.session_store :active_record_store, key: "_hobo_session", expire_after: 90.minutes
end
