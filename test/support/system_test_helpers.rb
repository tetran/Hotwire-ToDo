module SystemTestHelpers
  def sign_in_as(user)
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "HoboTest!Str0ng#2024"
    click_button "Login"
  end

  def open_project_menu
    selector = ".project-selector[data-controller='menu']"
    find(selector)
    wait_for_stimulus_controller(selector, "menu")
    find("#{selector} .menu-button").click
    find("#{selector} .menu-navigation:not(.hidden)")
  end

  private

    def wait_for_stimulus_controller(selector, controller_name, timeout_ms: 5000)
      connected = page.evaluate_async_script(<<~JS, selector, controller_name, timeout_ms)
        var selector = arguments[0];
        var name = arguments[1];
        var timeoutMs = arguments[2];
        var done = arguments[3];
        var el = document.querySelector(selector);
        var timerId = setTimeout(function() { done(false); }, timeoutMs);
        var check = function() {
          if (window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(el, name)) {
            clearTimeout(timerId);
            done(true);
          } else {
            requestAnimationFrame(check);
          }
        };
        check();
      JS
      return if connected

      raise "Stimulus controller '#{controller_name}' did not connect " \
            "on '#{selector}' within #{timeout_ms}ms"
    end
end
