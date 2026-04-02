require "test_helper"
require "support/system_test_helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemTestHelpers

  driven_by :selenium, using: (ENV["CI"] ? :headless_chrome : :chrome), screen_size: [1400, 1400]
end
