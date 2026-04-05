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
    // When showModal() is used, clicks on the ::backdrop pseudo-element
    // may register with event.target pointing to the dialog itself, or may
    // behave inconsistently across browsers. Use bounding-rect detection to
    // reliably identify clicks outside the visible dialog box.
    const rect = this.modalTarget.getBoundingClientRect()
    const outside =
      event.clientX < rect.left ||
      event.clientX > rect.right ||
      event.clientY < rect.top ||
      event.clientY > rect.bottom
    if (outside) {
      this.modalTarget.close()
    }
  }
}
