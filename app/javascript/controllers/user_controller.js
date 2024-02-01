import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatarPreview", "avatarInput", "notify", "field", "reloadField", "form", "submit"]

  connect() {}

  fieldModified() {
    const getModifiedFields = (targets) =>
      this[`${targets}Targets`].filter(element => element.value !== element.dataset.initial).map(element => element.name);

    const modifiedFields = getModifiedFields('field');
    const modifiedReloadFields = getModifiedFields('reloadField');
    const isModified = modifiedFields.length > 0 || modifiedReloadFields.length > 0 || this.avatarInputTarget.value !== "";

    this.submitTarget.disabled = !isModified;
    const notifyClass = isModified ? "animate--in" : "animate--out";
    this.notifyTarget.classList.remove("animate--in", "animate--out")
    this.notifyTarget.classList.add(notifyClass);
    this.formTarget.setAttribute("data-turbo-frame", modifiedReloadFields ? "_top" : "modal");
  }

  updateAvatar(event) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = event => this.avatarPreviewTarget.src = event.target.result;
    reader.readAsDataURL(file);

    this.fieldModified();
  }
}
