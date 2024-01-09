import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatarPreview", "avatarInput", "userActions", "notify", "field", "form"]

  connect() {}

  fieldModified() {
    const modifiedFields = this.fieldTargets.filter(element => document.getElementById(element.id + "_current")?.value !== element.value);
    const isModified = modifiedFields.length > 0;
    const isLocaleModified = modifiedFields.some(element => element.id === "user_locale");

    this.toggleElements(this.userActionsTarget.querySelectorAll("input,button"), !isModified);
    this.notifyTarget.classList.toggle("show", isModified);
    this.formTarget.setAttribute("data-turbo-frame", isLocaleModified ? "_top" : "modal");
  }

  toggleElements(elements, isDisabled) {
    elements.forEach(element => element.disabled = isDisabled);
  }

  updatePreview(event) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = event => this.avatarPreviewTarget.src = event.target.result;
    reader.readAsDataURL(file);

    this.fieldModified();
  }
}
