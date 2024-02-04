import { Controller } from "@hotwired/stimulus"
import { popupMenu } from "controllers/mixins/popupMenu"

export default class extends Controller {
  static targets = [ "menu" ]

  connect() {
    popupMenu(this)
  }
}
