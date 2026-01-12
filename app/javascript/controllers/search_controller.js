import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'input', 'modal']

  connect() {
    this.debounceTimeout = null
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  expand() {
    if (!this.formTarget.classList.contains('expanded')) {
      this.formTarget.classList.add('expanded')
    }
    this.inputTarget.focus()
  }

  collapse() {
    if (this.inputTarget.value.trim().length === 0) {
      this.formTarget.classList.remove('expanded')
      this.hideModal()
    }
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
    if (query.length === 0) {
      this.hideModal()
      return
    }

    this.showModal()
    const frame = this.modalTarget.querySelector('turbo-frame')
    if (frame) {
      const url = `/tasks/searches?q=${encodeURIComponent(query)}`
      frame.setAttribute('src', url)
    }
  }

  close() {
    this.hideModal()
    this.inputTarget.value = ''
    this.formTarget.classList.remove('expanded')
  }

  showModal() {
    this.modalTarget.classList.remove('hidden')
  }

  hideModal() {
    this.modalTarget.classList.add('hidden')
  }

  closeWithKeyboard(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  closeBackground(event) {
    if (!this.formTarget.classList.contains('expanded')) {
      return
    }
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
