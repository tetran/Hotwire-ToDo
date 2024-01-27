import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["username"]

  connect() {
  }

  // webauthn
  login(e) {
    e.preventDefault()
    const challege = Uint8Array.from(this.data.get("challenge"), c => c.charCodeAt(0))
    const option = {
      challenge: challege
    }
    navigator.credentials.get({ publicKey: option }).then((assertion) => {
      console.log(assertion)
    })
  }
}
