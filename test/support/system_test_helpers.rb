module SystemTestHelpers
  def sign_in_as(user)
    visit login_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: user.email
    fill_in I18n.t("activerecord.attributes.user.password"), with: "HoboTest!Str0ng#2024"
    click_button I18n.t("sessions.new.submit")
  end

  def open_project_menu
    selector = ".project-selector[data-controller='menu']"
    find(selector)
    wait_for_stimulus_controller(selector, "menu")

    3.times do |i|
      find("#{selector} .menu-button").click
      break if has_css?("#{selector} .menu-navigation:not(.hidden)", wait: 1)
      raise "Project menu failed to stay open after 3 attempts" if i == 2
    end
  end

  private

    def wait_for_stimulus_controller(selector, controller_name, timeout_ms: 5000)
      connected = page.evaluate_async_script(<<~JS, selector, controller_name, timeout_ms)
        var selector = arguments[0];
        var name = arguments[1];
        var timeoutMs = arguments[2];
        var done = arguments[3];
        var timerId = setTimeout(function() { done(false); }, timeoutMs);
        var check = function() {
          var el = document.querySelector(selector);
          if (el && window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(el, name)) {
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
