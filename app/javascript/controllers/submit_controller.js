import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['submit']

  connect() {
    this.submitTarget.addEventListener('click', event => {
      if (!confirm(event.target.dataset.confirm)) {
        event.preventDefault()
        return
      }

      // ここで待機画面を表示する
      this.showWaitingScreen()
    })
  }

  showWaitingScreen() {
    document.getElementById('loader-wrapper').style.display = 'block'
  }

  hideWaitingScreen() {
    document.getElementById('loader-wrapper').style.display = 'none'
  }
}
