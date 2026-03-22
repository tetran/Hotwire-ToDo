# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.object_src  :none
    policy.base_uri    :self
    policy.frame_ancestors :none

    policy.script_src :self
    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src(*policy.script_src, :unsafe_eval,
                      "http://#{ViteRuby.config.host_with_port}") if Rails.env.development?
    # Allow blob: for vite-ruby test builds
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    policy.style_src :self, "https://fonts.googleapis.com", "https://cdn.jsdelivr.net"
    # Allow @vite/client to hot reload style changes in development
    policy.style_src(*policy.style_src, :unsafe_inline) if Rails.env.development?

    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, :data
    policy.connect_src :self
    policy.connect_src(*policy.connect_src,
                       "ws://#{ViteRuby.config.host_with_port}",
                       "http://#{ViteRuby.config.host_with_port}") if Rails.env.development?
  end

  # Generate nonces for permitted inline scripts and styles.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
