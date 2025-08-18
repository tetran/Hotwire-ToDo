export const popupMenu = controller => {
  Object.assign(controller, {
    toggleMenu() {
      this.menuTarget.classList.toggle('hidden')
    },

    hideMenu() {
      if (document.getElementById('modal').hasAttribute('src')) {
        return
      }

      this.menuTarget.classList.add('hidden')
    },

    // hide modal when clicking ESC
    // action: "keyup@window->turbo-modal#closeWithKeyboard"
    closeWithKeyboard(e) {
      if (e.code === 'Escape') {
        this.hideMenu()
      }
    },

    // hide modal when clicking outside of modal
    // action: "click@window->turbo-modal#closeBackground"
    closeBackground(e) {
      if (e && this.element.contains(e.target)) {
        return
      }
      this.hideMenu()
    }
  })
}
