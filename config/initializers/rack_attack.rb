module Rack
  class Attack
    unless Rails.env.development?
      throttle("admin_login/ip", limit: 5, period: 60) do |req|
        req.ip if req.path == "/api/v1/admin/session" && req.post?
      end

      throttle("admin_login/email", limit: 5, period: 60) do |req|
        next unless req.path == "/api/v1/admin/session" && req.post?

        email = if req.media_type&.include?("application/json")
                  body = req.body.read
                  req.body.rewind
                  begin
                    JSON.parse(body)["email"]
                  rescue JSON::ParserError
                    nil
                  end
                else
                  req.params["email"]
                end
        email&.downcase&.strip
      end

      self.throttled_responder = lambda do |request|
        match_data = request.env["rack.attack.match_data"]
        now = match_data[:epoch_time] || Time.now.to_i
        retry_after = (match_data[:period] - (now % match_data[:period])).to_s
        [
          429,
          { "Content-Type" => "application/json", "Retry-After" => retry_after },
          [{ error: "Too many requests" }.to_json],
        ]
      end
    end
  end
end
