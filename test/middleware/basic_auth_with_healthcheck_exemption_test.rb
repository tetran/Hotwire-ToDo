require "test_helper"
require "base64"

class BasicAuthWithHealthcheckExemptionTest < ActiveSupport::TestCase
  USERNAME = "user".freeze
  PASSWORD = "secret".freeze

  setup do
    downstream = ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    @middleware = BasicAuthWithHealthcheckExemption.new(downstream, USERNAME, PASSWORD)
  end

  # Core paths

  test "GET /up without Authorization header passes through" do
    status, _headers, body = @middleware.call(rack_env("/up"))

    assert_equal 200, status
    assert_equal ["OK"], body
  end

  test "GET / without Authorization header returns 401 with WWW-Authenticate" do
    status, headers, _body = @middleware.call(rack_env("/"))

    assert_equal 401, status
    # Rack 3 uses lowercase header names.
    assert_equal %(Basic realm="Restricted"), headers["www-authenticate"]
  end

  test "GET / with correct credentials passes through" do
    env = rack_env("/", basic_auth: [USERNAME, PASSWORD])
    status, _headers, body = @middleware.call(env)

    assert_equal 200, status
    assert_equal ["OK"], body
  end

  test "GET / with correct username but wrong password returns 401" do
    env = rack_env("/", basic_auth: [USERNAME, "wrong"])
    status, _headers, _body = @middleware.call(env)

    assert_equal 401, status
  end

  test "GET / with wrong username but correct password returns 401" do
    env = rack_env("/", basic_auth: ["wrong", PASSWORD])
    status, _headers, _body = @middleware.call(env)

    assert_equal 401, status
  end

  test "GET /up with wrong credentials still passes through (exempt wins)" do
    env = rack_env("/up", basic_auth: %w[wrong wrong])
    status, _headers, body = @middleware.call(env)

    assert_equal 200, status
    assert_equal ["OK"], body
  end

  # Exempt semantics edge cases

  test "HEAD /up without Authorization header passes through" do
    env = rack_env("/up", method: "HEAD")
    status, _headers, _body = @middleware.call(env)

    assert_equal 200, status
  end

  test "GET /up/ (trailing slash) without Authorization header returns 401" do
    status, _headers, _body = @middleware.call(rack_env("/up/"))

    assert_equal 401, status
  end

  test "GET /UP (uppercase) without Authorization header returns 401" do
    status, _headers, _body = @middleware.call(rack_env("/UP"))

    assert_equal 401, status
  end

  test "GET /up?foo=bar without Authorization header passes through" do
    env = rack_env("/up?foo=bar")
    status, _headers, body = @middleware.call(env)

    assert_equal 200, status
    assert_equal ["OK"], body
  end

  test "GET / with malformed Authorization header returns 4xx without raising" do
    env = rack_env("/")
    env["HTTP_AUTHORIZATION"] = "Basic zzzzz"

    # Delegated to Rack::Auth::Basic. Its default behavior returns 400 Bad Request
    # for malformed credentials. The test pins the contract: client error, no exception.
    status, _headers, _body = @middleware.call(env)

    assert_operator status, :>=, 400
    assert_operator status, :<, 500
  end

  private

    def rack_env(path, method: "GET", basic_auth: nil)
      env = Rack::MockRequest.env_for(path, method: method)
      if basic_auth
        encoded = Base64.strict_encode64(basic_auth.join(":"))
        env["HTTP_AUTHORIZATION"] = "Basic #{encoded}"
      end
      env
    end
end
