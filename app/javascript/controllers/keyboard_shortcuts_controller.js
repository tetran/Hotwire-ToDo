import { Controller } from '@hotwired/stimulus'

// Global keyboard shortcuts for the user-side Hotwire UI.
//
// Attached once to <body> in application.html.erb. Since Turbo morph refreshes
// preserve the <body> element, the controller's state (g-prefix, listeners)
// survives page transitions without re-connecting.
//
// See docs & plan: Issue #14.
export default class extends Controller {
  static targets = ['helpDialog']
  static values = {
    inboxId: String
  }

  connect() {
    this.gPrefixActive = false
    this.gPrefixTimer = null
  }

  disconnect() {
    this._clearGPrefix()
  }

  // ---------------- Main dispatcher ----------------

  handleKeydown(e) {
    // IME composition: never intercept
    if (this._isComposing(e)) return

    const key = e.key

    // Cmd/Ctrl + Enter — form submit (works inside inputs)
    if (key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      this._submitForm(e)
      return
    }

    // Escape — unified close (works inside inputs)
    if (key === 'Escape') {
      this._handleEscape(e)
      return
    }

    // All other shortcuts must NOT trigger while typing
    if (this._isTypingInInput()) return

    // Modifier keys other than Shift disqualify the key as a shortcut
    if (e.metaKey || e.ctrlKey || e.altKey) return

    // `g` prefix sequence — only consume the key when the prefix is active
    if (this.gPrefixActive) {
      this._handleGPrefixFollowup(e, key)
      return
    }

    // Single-key shortcuts
    switch (key) {
      case '/':
        if (this._isModalOpen()) return
        this._focusSearch(e)
        return
      case 'n':
        if (this._isModalOpen()) return
        this._newTask(e)
        return
      case '?':
        this._openHelp(e)
        return
      case 'g':
        if (this._isModalOpen()) return
        this._startGPrefix(e)
        return
      default:
        return
    }
  }

  // ---------------- Action handlers (exposed via data-action) ----------------

  openHelp(e) {
    // Called by click on menu item. Prevent default link-like behavior.
    e?.preventDefault?.()
    this._showHelpDialog()
  }

  closeHelp(e) {
    e?.preventDefault?.()
    if (this.hasHelpDialogTarget && this.helpDialogTarget.open) {
      this.helpDialogTarget.close()
    }
  }

  onHelpBackdropClick(e) {
    // Dialog click handler: if the click target is the dialog itself
    // (i.e. the backdrop area, not any child), close it.
    if (e.target === this.helpDialogTarget) {
      this.helpDialogTarget.close()
    }
  }

  // ---------------- Internal handlers ----------------

  _focusSearch(e) {
    const searchEl = document.querySelector('[data-controller~="search"]')
    if (!searchEl) return
    const ctrl = this.application.getControllerForElementAndIdentifier(searchEl, 'search')
    if (!ctrl || typeof ctrl.open !== 'function') return
    e.preventDefault()
    ctrl.open()
  }

  _newTask(e) {
    const frame = document.getElementById('new_task')
    if (!frame) return
    // Skip if the frame already holds a rendered form (multiple children or
    // non-button elements beyond the default add-task button)
    if (this._newTaskFrameHasForm(frame)) return

    const projectId = this._currentProjectId() || this.inboxIdValue
    if (!projectId) return

    e.preventDefault()
    frame.setAttribute('src', `/tasks/new?project_id=${encodeURIComponent(projectId)}`)
  }

  _openHelp(e) {
    // Input/composition guards already applied in handleKeydown before reaching here.
    if (!this.hasHelpDialogTarget) return
    if (this.helpDialogTarget.open) return
    e.preventDefault()
    this._showHelpDialog()
  }

  _showHelpDialog() {
    if (!this.hasHelpDialogTarget) return
    if (this.helpDialogTarget.open) return
    this.helpDialogTarget.showModal()
  }

  _handleEscape(e) {
    // 1) Clear active g-prefix — swallow the Esc
    if (this.gPrefixActive) {
      this._clearGPrefix()
      e.preventDefault()
      return
    }

    // 2) Close the topmost open <dialog>
    const openDialogs = document.querySelectorAll('dialog[open]')
    if (openDialogs.length > 0) {
      const topDialog = openDialogs[openDialogs.length - 1]
      topDialog.close()
      e.preventDefault()
      return
    }

    // 3) Close any open popup menus. No guard on turbo-frame#modal src
    // attribute: it is not reliably cleared when a task-detail dialog is
    // dismissed via native Esc, so using it here would leave menus stuck
    // open for the rest of the session.
    const openMenus = document.querySelectorAll('.menu-navigation:not(.hidden)')
    if (openMenus.length > 0) {
      openMenus.forEach(m => m.classList.add('hidden'))
      e.preventDefault()
    }
  }

  _submitForm(e) {
    // Composition guard already applied in handleKeydown.
    const target = e.target
    if (!target) return
    const isEditable = target.tagName === 'TEXTAREA' ||
                       target.tagName === 'TRIX-EDITOR' ||
                       target.isContentEditable
    if (!isEditable) return
    const form = target.closest('form')
    if (!form) return
    e.preventDefault()
    form.requestSubmit()
  }

  _startGPrefix(e) {
    e.preventDefault()
    this.gPrefixActive = true
    if (this.gPrefixTimer) clearTimeout(this.gPrefixTimer)
    this.gPrefixTimer = setTimeout(() => this._clearGPrefix(), 1000)
  }

  _handleGPrefixFollowup(e, key) {
    // Consume any follow-up key: navigate if valid, otherwise just clear
    this._clearGPrefix()
    if (key === 'i') {
      if (!this.inboxIdValue) return
      e.preventDefault()
      this._visit(`/projects/${encodeURIComponent(this.inboxIdValue)}`)
    } else if (key === 'p') {
      e.preventDefault()
      this._visit('/')
    }
  }

  _clearGPrefix() {
    this.gPrefixActive = false
    if (this.gPrefixTimer) {
      clearTimeout(this.gPrefixTimer)
      this.gPrefixTimer = null
    }
  }

  _visit(path) {
    if (window.Turbo && typeof window.Turbo.visit === 'function') {
      window.Turbo.visit(path)
    } else {
      window.location.href = path
    }
  }

  // ---------------- Predicates ----------------

  _isTypingInInput() {
    const el = document.activeElement
    if (!el) return false
    const tag = el.tagName
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || tag === 'TRIX-EDITOR') {
      return true
    }
    return el.isContentEditable === true
  }

  _isComposing(e) {
    return e.isComposing === true || e.keyCode === 229
  }

  _isModalOpen() {
    // Do not rely on turbo-frame#modal's `src` attribute — it persists after
    // a task-detail dialog is dismissed via native Esc (turbo_modal_controller
    // only clears it via click->hideModal). The actually-visible dialog is
    // the correct signal.
    return document.querySelector('dialog[open]') !== null
  }

  _currentProjectId() {
    const el = document.querySelector('[data-current-project-id]')
    return el?.dataset.currentProjectId || null
  }

  _newTaskFrameHasForm(frame) {
    // Default state: contains a single <form> (the add-task button).
    // When a new task form is loaded it replaces the button with the
    // task-form markup which contains a form with a task name input.
    return frame.querySelector('form.task-form, .task-form') !== null
  }
}
