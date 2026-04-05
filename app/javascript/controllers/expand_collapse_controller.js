import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content', 'icon']
  static values = { key: String }

  connect() {
    if (!this.hasKeyValue) return
    // Only restore the "expanded" state — the template always renders
    // content with `hidden`, so a stored "collapsed" value matches the
    // default and requires no action.
    if (sessionStorage.getItem(this.storageKey) === 'expanded') {
      this.contentTarget.hidden = false
      this.iconTarget.textContent = 'expand_less'
    }
  }

  toggle() {
    const hidden = this.contentTarget.hidden
    this.contentTarget.hidden = !hidden
    this.iconTarget.textContent = hidden ? 'expand_less' : 'expand_more'
    if (this.hasKeyValue) {
      sessionStorage.setItem(this.storageKey, hidden ? 'expanded' : 'collapsed')
    }
  }

  get storageKey() {
    return `expand-collapse:${this.keyValue}`
  }
}
