import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatarPreview", "avatarInput", "userActions", "notify"]

  connect() {
  }

  enableActions() {
    this.userActionsTarget.querySelectorAll("input,button").forEach((element) => {
      element.disabled = false;
    });
    this.notifyTarget.classList.add("show");
  }

  updatePreview(event) {
    const file = event.target.files[0];
    if (!file) {
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      this.avatarPreviewTarget.src = event.target.result;
    };
    reader.readAsDataURL(file);

    this.enableActions();
  }
}
