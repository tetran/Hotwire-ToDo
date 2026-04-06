import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="recurrence-scope-dialog"
// Attached to the <dialog> element that asks users to pick edit scope
// when they have modified template fields of a recurring task.
export default class extends Controller {
  static targets = ['dialog']

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close()
    }
  }

  cancel(event) {
    if (event) event.preventDefault()
    this.close()
  }

  chooseOnlyThis(event) {
    if (event) event.preventDefault()
    this.submitWith('only_this')
  }

  chooseAllFuture(event) {
    if (event) event.preventDefault()
    this.submitWith('all_future')
  }

  onBackdropClick(event) {
    const rect = this.dialogTarget.getBoundingClientRect()
    const outside =
      event.clientX < rect.left ||
      event.clientX > rect.right ||
      event.clientY < rect.top ||
      event.clientY > rect.bottom
    if (outside) this.close()
  }

  submitWith(scope) {
    const form = this.element.closest('form')
    this.close()
    if (!form) return
    const formController = this.application.getControllerForElementAndIdentifier(form, 'recurrence-form')
    if (formController && typeof formController.submitWithScope === 'function') {
      formController.submitWithScope(scope)
    } else {
      const input = form.querySelector('[data-recurrence-form-target="scope"]')
      if (input) input.value = scope
      if (typeof form.requestSubmit === 'function') {
        form.requestSubmit()
      } else {
        form.submit()
      }
    }
  }
}
