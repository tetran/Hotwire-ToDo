import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="recurrence-form"
// Attached to the <form> element.
//
// Responsibilities:
// - Hide all recurrence detail fields when frequency="none" (not recurring)
// - Toggle weekday fieldset visibility based on frequency=weekly
// - On submit: when editing an existing recurring task, detect whether
//   template fields changed and, if so, open the scope dialog to let the
//   user choose "only this" vs "all future" before submitting.
export default class extends Controller {
  static targets = ['weeklyOnly', 'frequency', 'scope', 'details', 'intervalUnit']
  static values = {
    hasSeries: String,
    isPersisted: String,
  }

  connect() {
    this.hasSeries = this.hasSeriesValue === 'true'
    this.isPersisted = this.isPersistedValue === 'true'
    this.toggleDetails()
    this.toggleWeeklyOnly()
    this.toggleIntervalUnit()
    this.initialTemplateSnapshot = this.captureTemplateSnapshot()
    this.submitting = false
  }

  onFrequencyChange() {
    this.toggleDetails()
    this.toggleWeeklyOnly()
    this.toggleIntervalUnit()
  }

  toggleIntervalUnit() {
    if (!this.hasIntervalUnitTarget || !this.hasFrequencyTarget) return
    const current = this.frequencyTarget.value
    this.intervalUnitTargets.forEach((el) => {
      el.hidden = el.dataset.frequency !== current
    })
  }

  toggleDetails() {
    if (!this.hasDetailsTarget || !this.hasFrequencyTarget) return
    const isNone = this.frequencyTarget.value === 'none'
    this.detailsTarget.hidden = isNone
  }

  toggleWeeklyOnly() {
    if (!this.hasWeeklyOnlyTarget || !this.hasFrequencyTarget) return
    const isWeekly = this.frequencyTarget.value === 'weekly'
    this.weeklyOnlyTarget.hidden = !isWeekly
  }

  onSubmit(event) {
    if (this.submitting) return
    if (!this.isPersisted || !this.hasSeries) return

    // If user chose "none" (don't recur), skip the dialog — the backend
    // will stop the series based on the frequency value.
    if (this.hasFrequencyTarget && this.frequencyTarget.value === 'none') {
      this.setScope('only_this')
      return
    }

    const templateChanged = this.templateFieldsChanged()
    if (!templateChanged) {
      this.setScope('only_this')
      return
    }

    // Template fields changed — need the user to choose.
    event.preventDefault()
    const dialog = this.element.querySelector('.task-form__scope-dialog')
    if (dialog && typeof dialog.showModal === 'function') {
      dialog.showModal()
    }
  }

  setScope(value) {
    if (this.hasScopeTarget) this.scopeTarget.value = value
  }

  // Called by recurrence-scope-dialog controller after user chooses.
  submitWithScope(scope) {
    this.setScope(scope)
    this.submitting = true
    if (typeof this.element.requestSubmit === 'function') {
      this.element.requestSubmit()
    } else {
      this.element.submit()
    }
  }

  templateFieldsChanged() {
    const current = this.captureTemplateSnapshot()
    const initial = this.initialTemplateSnapshot || {}
    for (const key of Object.keys(current)) {
      if (current[key] !== initial[key]) return true
    }
    return false
  }

  captureTemplateSnapshot() {
    const form = this.element
    const snap = {}
    snap.frequency = this.readValue(form, 'task[recurrence][frequency]')
    snap.interval = this.readValue(form, 'task[recurrence][interval]')
    snap.end_mode = this.readRadioValue(form, 'task[recurrence][end_mode]')
    snap.count = this.readValue(form, 'task[recurrence][count]')
    snap.until_date = this.readValue(form, 'task[recurrence][until_date]')
    snap.by_weekday = this.readCheckboxGroup(form, 'task[recurrence][by_weekday][]')
    return snap
  }

  readValue(form, name) {
    const el = form.querySelector(`[name="${name}"]`)
    return el ? el.value : ''
  }

  readRadioValue(form, name) {
    const els = form.querySelectorAll(`input[type="radio"][name="${name}"]`)
    for (const el of els) {
      if (el.checked) return el.value
    }
    return ''
  }

  readCheckboxGroup(form, name) {
    const els = form.querySelectorAll(`input[type="checkbox"][name="${name}"]`)
    const values = []
    els.forEach((el) => {
      if (el.checked) values.push(el.value)
    })
    return values.sort().join(',')
  }
}
