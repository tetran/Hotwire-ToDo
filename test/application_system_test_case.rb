require "test_helper"
require "support/system_test_helpers"

# Some form controls (toggle chips, custom checkboxes) visually hide the
# native <input> and present the <label> as the interactive surface. Clicking
# the label is equivalent to clicking the input, so let Capybara do that
# automatically for check/uncheck/choose.
Capybara.automatic_label_click = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemTestHelpers

  driven_by :selenium, using: (ENV["CI"] ? :headless_chrome : :chrome), screen_size: [1400, 1400]
end
