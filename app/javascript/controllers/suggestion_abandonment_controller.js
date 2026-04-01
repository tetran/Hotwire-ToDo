import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    url: String,
    responseId: Number,
  }

  connect() {
    this.submitted = false
    this.boundBeforeVisit = this.abandon.bind(this)
    this.boundBeforeUnload = this.abandon.bind(this)
    this.boundSubmitStart = this.markSubmittedEarly.bind(this)

    document.addEventListener('turbo:before-visit', this.boundBeforeVisit)
    window.addEventListener('beforeunload', this.boundBeforeUnload)
    this.element.addEventListener('turbo:submit-start', this.boundSubmitStart)
  }

  disconnect() {
    this.abandon()
    document.removeEventListener('turbo:before-visit', this.boundBeforeVisit)
    window.removeEventListener('beforeunload', this.boundBeforeUnload)
    this.element.removeEventListener('turbo:submit-start', this.boundSubmitStart)
  }

  markSubmittedEarly() {
    this.submitted = true
  }

  markSubmitted(event) {
    if (event.detail.success) {
      this.submitted = true
    }
  }

  abandon() {
    if (this.submitted) return

    const formData = new FormData()
    formData.append('suggestion_response_id', this.responseIdValue)
    formData.append(
      'authenticity_token',
      document.querySelector('meta[name="csrf-token"]').content,
    )

    navigator.sendBeacon(this.urlValue, formData)
  }
}
