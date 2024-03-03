import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-modal"
export default class extends Controller {
  static targets = ["header", "body"];

  connect() {
    this.element.showModal();
  }

  hideModal(e) {
    if (e) {
      // prevent default link behavior
      e.preventDefault()
      // prevent bubbling up the DOM tree to avoid triggering the click event on the window
      e.stopPropagation()
    }
    document.getElementById("modal").removeAttribute("src")
    document.querySelector(".modal-base").remove()
  }

  // hide modal when clicking outside of modal
  // action: "click->turbo-modal#closeBackground"
  closeBackground(e) {
    if (e && (this.headerTarget.contains(e.target) || this.bodyTarget.contains(e.target))) {
      return
    }
    this.hideModal()
  }
}
