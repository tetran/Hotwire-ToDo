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

    def wait_for_stimulus_controller(selector, controller_name)
      page.evaluate_async_script(<<~JS, selector, controller_name)
        var selector = arguments[0];
        var name = arguments[1];
        var done = arguments[2];
        var el = document.querySelector(selector);
        var check = function() {
          if (window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(el, name)) {
            done(true);
          } else {
            requestAnimationFrame(check);
          }
        };
        check();
      JS
    end
end
