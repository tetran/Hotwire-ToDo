require "application_system_test_case"

class ProjectFlowTest < ApplicationSystemTestCase
  test "list, create, show, and edit projects" do
    user = users(:regular_user)

    sign_in_as(user)
    open_project_menu
    assert_text "Test Project One"
    assert_text "Test Project Two"

    click_link "Add project"
    project_name = "Client Onboarding"
    within("dialog.modal-base") do
      fill_in "Project name", with: project_name
      find(".project-form__submit").click
    end

    assert_selector ".project-name", text: project_name

    open_project_menu
    within(".project-selector__list") do
      find("li", text: project_name).find(".project-selector__list-item__edit").click
    end

    updated_name = "Client Onboarding v2"
    within("dialog.modal-base") do
      fill_in "Project name", with: updated_name
      find(".project-form__submit").click
    end

    assert_selector ".project-name", text: updated_name
  end
end
