import { Controller } from '@hotwired/stimulus'
import { popupMenu } from 'controllers/mixins/popupMenu'

export default class extends Controller {
  static targets = ['menu', 'form']

  connect() {
    popupMenu(this)
  }

  clear() {
    this.formTarget.reset()
    const errors = this.formTarget.querySelectorAll('.simple-error')
    errors.forEach(error => {
      error.remove()
    })
  }
}
