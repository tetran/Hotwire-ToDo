import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-modal"
export default class extends Controller {
  connect() {
    this.element.classList.add("animate")
    this.element.addEventListener("animationend", () => this.element.remove())
  }
}
