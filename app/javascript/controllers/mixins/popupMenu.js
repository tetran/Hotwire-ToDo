export const popupMenu = controller => {
  Object.assign(controller, {
    toggleMenu(e) {
      e?.stopPropagation()
      this._closeOtherMenus()
      this.menuTarget.classList.toggle('hidden')
    },

    _closeOtherMenus() {
      document.querySelectorAll('.menu-container > .menu-navigation:not(.hidden)').forEach(nav => {
        if (nav !== this.menuTarget) {
          nav.classList.add('hidden')
        }
      })
    },

    hideMenu() {
      if (document.getElementById('modal').hasAttribute('src')) {
        return
      }

      this.menuTarget.classList.add('hidden')
    },

    // hide modal when clicking outside of modal
    // action: "click@window->turbo-modal#closeBackground"
    //
    // Escape-key handling is delegated to the global
    // `keyboard-shortcuts` controller (see issue #14).
    closeBackground(e) {
      if (e && this.element.contains(e.target)) {
        return
      }
      this.hideMenu()
    }
  })
}
