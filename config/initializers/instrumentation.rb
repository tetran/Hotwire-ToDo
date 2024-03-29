# https://railsguides.jp/active_support_instrumentation.html#railsフレームワーク用フック
# https://haracane.github.io/2015/12/13/notify-rails-slow-response/
# ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, started, finished, unique_id, data|
#   Rails.logger.debug { "★★★★★★★★★★★★★★★★★ #{name} Received! (started: #{started}, finished: #{finished})" }
# end
# 動きは上と同じだが、書き方が違う
# ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
#   event = ActiveSupport::Notifications::Event.new(*args)
#   Rails.logger.debug "☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆ #{event.name} Received! (started: #{event.time}, finished: #{event.end}, duration: #{event.duration} ms)"
# end

# ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
#   event = ActiveSupport::Notifications::Event.new(*args)
#   Rails.logger.debug { "[DB Access] (SQL: #{event.payload[:sql]}, Bindings: #{event.payload[:binds]}, duration: #{event.duration} ms)" }
# end

ActiveSupport::Notifications.subscribe "chat.openai" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug { "\e[1m\e[31mOpenAI Chat Request \e[0m\e[34m(Duration: #{event.duration.to_i.to_formatted_s(:delimited)}[ms] | Payloads: #{event.payload.to_json})\e[0m" }
end
