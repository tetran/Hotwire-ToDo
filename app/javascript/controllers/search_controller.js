import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'modal']

  connect() {
    this.debounceTimeout = null
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  open() {
    this.modalTarget.showModal()
    this.inputTarget.focus()
  }

  search() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }

    this.debounceTimeout = setTimeout(() => {
      this.performSearch()
    }, 300)
  }

  performSearch() {
    const query = this.inputTarget.value.trim()
    const frame = this.modalTarget.querySelector('turbo-frame')
    if (!frame) return

    if (query.length === 0) {
      frame.removeAttribute('src')
      frame.innerHTML = ''
      return
    }

    const url = `/tasks/searches?q=${encodeURIComponent(query)}`
    frame.setAttribute('src', url)
  }

  onClose() {
    this.inputTarget.value = ''
    const frame = this.modalTarget.querySelector('turbo-frame')
    if (frame) {
      frame.removeAttribute('src')
      frame.innerHTML = ''
    }
  }

  onBackdropClick(event) {
    if (event.target === this.modalTarget) {
      this.modalTarget.close()
    }
  }
}
