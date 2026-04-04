import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content', 'icon']

  toggle() {
    const hidden = this.contentTarget.hidden
    this.contentTarget.hidden = !hidden
    this.iconTarget.textContent = hidden ? 'expand_less' : 'expand_more'
  }
}
