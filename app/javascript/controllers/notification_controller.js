import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.classList.add("animate")
    this.element.addEventListener("animationend", () => this.element.remove())
  }
}
