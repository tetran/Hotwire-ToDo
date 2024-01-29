key = "_hobo_session".freeze
expire_after = 90.minutes.freeze
begin
  Rails.application.config.session_store :redis_session_store,
                                         key: key,
                                         redis: {
                                           expire_after: expire_after,
                                           key_prefix: 'session:',
                                           url: "#{ENV.fetch("REDIS_URL")}/1",
                                         }
rescue => e
  # When Redis is not available, fallback to ActiveRecord session store
  Sentry.capture_exception(e)
  Rails.logger.error("Redis is not available, falling back to ActiveRecord session store\n#{e}")

  Rails.application.config.session_store :active_record_store, key: key, expire_after: expire_after
end
