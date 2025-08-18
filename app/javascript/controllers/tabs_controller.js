import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['tab', 'tabPanel']

  changeTab(event) {
    const newActiveTab = event.target

    this.tabTargets.forEach((tab, _index) => {
      const panelName = tab.getAttribute('data-panel')
      const panel = this.tabPanelTargets.find(p => p.id === panelName)

      const isActive = tab === newActiveTab
      tab.classList.toggle('active', isActive)
      panel.classList.toggle('hidden', !isActive)
    })
  }
}
