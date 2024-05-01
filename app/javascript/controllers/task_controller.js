import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {}

  playComplete() {
    document.getElementById('complete-sound').play();
  }
}
