require "application_system_test_case"

class KeyboardShortcutsTest < ApplicationSystemTestCase
  setup do
    @user = users(:regular_user)
    sign_in_as(@user)
    # Ensure the landing page is fully rendered (header + search controller
    # inside it) before firing synthetic keydown events.
    assert_selector ".project-header"
    assert_selector ".search-container[data-controller='search']", visible: :all
    wait_for_keyboard_shortcuts_ready
  end

  test "slash focuses the search box" do
    dispatch_key("/")
    assert_selector "dialog.search-modal[open]"
    assert_selector ".search-form__input:focus"
  end

  test "n opens the new task form in the current project" do
    dispatch_key("n")
    assert_selector "turbo-frame#new_task .task-form"
    assert_selector ".task-form__name--input"
  end

  test "question mark opens the shortcuts help modal" do
    dispatch_key("?", shift: true)
    assert_selector "dialog.shortcuts-help-modal[open]"
    assert_selector ".shortcuts-help-list"
  end

  test "escape closes the shortcuts help modal" do
    dispatch_key("?", shift: true)
    assert_selector "dialog.shortcuts-help-modal[open]"
    dispatch_key("Escape")
    assert_no_selector "dialog.shortcuts-help-modal[open]"
  end

  test "escape closes the hamburger menu" do
    # Regression: popup menus used to register their own keyup handler; the
    # global keyboard-shortcuts controller now owns that responsibility.
    find(".menu-container--header:not(.project-members) .menu-button").click
    assert_selector ".menu-container--header:not(.project-members) .menu-navigation:not(.hidden)"
    dispatch_key("Escape")
    assert_no_selector ".menu-container--header:not(.project-members) .menu-navigation:not(.hidden)"
  end

  test "g then i navigates to the inbox" do
    open_project_menu
    click_link "Test Project Two"
    assert_selector ".project-name", text: "Test Project Two"
    wait_for_keyboard_shortcuts_ready

    dispatch_key("g")
    dispatch_key("i")

    inbox = @user.inbox_project
    assert_current_path project_path(inbox)
  end

  test "g then p navigates to the project list root" do
    open_project_menu
    click_link "Test Project Two"
    assert_selector ".project-name", text: "Test Project Two"
    wait_for_keyboard_shortcuts_ready

    dispatch_key("g")
    dispatch_key("p")

    # Root `/` redirects to the user's inbox project, so verify we land on
    # the inbox page.
    inbox = @user.inbox_project
    assert_current_path project_path(inbox)
  end

  test "n is disabled while typing inside an input" do
    click_button I18n.t("tasks.add_task_btn.add_task")
    name_field = find(".task-form__name--input")
    name_field.click
    name_field.send_keys "x"
    name_field.send_keys "n"

    # The `n` should have been typed into the input rather than triggering
    # a new-task shortcut (which would have replaced the frame contents).
    assert_equal "xn", find(".task-form__name--input").value
  end

  test "escape clears an active g-prefix without navigating" do
    open_project_menu
    click_link "Test Project Two"
    assert_selector ".project-name", text: "Test Project Two"
    wait_for_keyboard_shortcuts_ready

    dispatch_key("g")
    dispatch_key("Escape")
    # After Esc the g-prefix is cleared, so pressing `i` alone is a no-op.
    dispatch_key("i")

    # We should still be on Test Project Two.
    assert_selector ".project-name", text: "Test Project Two"
  end

  test "help modal cannot be stacked" do
    dispatch_key("?", shift: true)
    assert_selector "dialog.shortcuts-help-modal[open]"
    # Second `?` should be a no-op; the dialog count stays at 1.
    dispatch_key("?", shift: true)
    assert_selector "dialog.shortcuts-help-modal[open]", count: 1
  end

  test "hamburger menu shortcut link opens the help modal" do
    find(".menu-container--header:not(.project-members) .menu-button").click
    find(".menu-list__shortcuts").click
    assert_selector "dialog.shortcuts-help-modal[open]"
  end

  test "slash still works after a task detail modal is closed via escape" do
    # Regression for PR #285 review: turbo_modal_controller only clears the
    # `#modal` frame's `src` attribute on click->hideModal, not on native
    # Esc dialog close. Relying on `src` for modal-open detection leaves
    # `/`, `n`, `g` shortcuts permanently disabled after one Esc-close.
    open_project_menu
    click_link "Test Project Two"
    assert_selector ".project-name", text: "Test Project Two"
    click_link "Test Task Two"
    assert_selector "dialog.modal-base[open]", text: "Test Task Two"

    dispatch_key("Escape")
    assert_no_selector "dialog.modal-base[open]"
    wait_for_keyboard_shortcuts_ready

    dispatch_key("/")
    assert_selector "dialog.search-modal[open]"
  end

  test "escape still closes popup menus after a task modal was closed via escape" do
    # Regression for PR #285 review: the old `_handleEscape` guard used
    # `#modal[src]`, which persists across native Esc dismissals and
    # prevented popup menus from closing for the rest of the session.
    open_project_menu
    click_link "Test Project Two"
    assert_selector ".project-name", text: "Test Project Two"
    click_link "Test Task Two"
    assert_selector "dialog.modal-base[open]", text: "Test Task Two"

    dispatch_key("Escape")
    assert_no_selector "dialog.modal-base[open]"
    wait_for_keyboard_shortcuts_ready

    find(".menu-container--header:not(.project-members) .menu-button").click
    assert_selector ".menu-container--header:not(.project-members) .menu-navigation:not(.hidden)"
    dispatch_key("Escape")
    assert_no_selector ".menu-container--header:not(.project-members) .menu-navigation:not(.hidden)"
  end

  private

    # Dispatches a synthetic keydown event directly on window so that the
    # keyboard-shortcuts controller receives it regardless of which element
    # currently has browser focus. Ruby-side string interpolation (with
    # `to_json` for safety) avoids Capybara/Selenium's `arguments[]`
    # passing quirks inside IIFE-wrapped scripts.
    def dispatch_key(key, shift: false, meta: false, ctrl: false)
      script = +"window.dispatchEvent(new KeyboardEvent('keydown', {"
      script << "key: #{key.to_json},"
      script << "shiftKey: #{shift},"
      script << "metaKey: #{meta},"
      script << "ctrlKey: #{ctrl},"
      script << "bubbles: true, cancelable: true"
      script << "}));"
      page.execute_script(script)
    end

    def wait_for_keyboard_shortcuts_ready
      page.evaluate_async_script(<<~JS)
        var done = arguments[0];
        var timerId = setTimeout(function() { done(false); }, 5000);
        var check = function() {
          if (window.Stimulus &&
              window.Stimulus.getControllerForElementAndIdentifier(document.body, "keyboard-shortcuts")) {
            clearTimeout(timerId);
            done(true);
          } else {
            requestAnimationFrame(check);
          }
        };
        check();
      JS
    end
end
