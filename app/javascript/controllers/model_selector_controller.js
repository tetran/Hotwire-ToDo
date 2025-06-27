import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "loading"]
  static values = { 
    providerId: Number,
    availableModelsUrl: String 
  }

  connect() {
    if (this.providerIdValue) {
      this.loadModels()
    }
  }

  providerIdValueChanged() {
    if (this.providerIdValue) {
      this.loadModels()
    } else {
      this.clearModels()
    }
  }

  async loadModels() {
    if (!this.providerIdValue) return

    this.showLoading()
    
    try {
      const url = this.availableModelsUrlValue.replace(':provider_id', this.providerIdValue)
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      
      if (data.error) {
        this.showError(data.error)
      } else {
        this.populateModels(data.models)
      }
    } catch (error) {
      console.error('Failed to load models:', error)
      this.showError('Failed to load available models')
    } finally {
      this.hideLoading()
    }
  }

  populateModels(models) {
    const select = this.selectTarget
    const currentValue = select.value
    
    // Clear existing options except the first one (placeholder)
    while (select.children.length > 1) {
      select.removeChild(select.lastChild)
    }

    // Add model options
    models.forEach(model => {
      const option = document.createElement('option')
      option.value = model.id
      option.textContent = model.display_name || model.name
      select.appendChild(option)
    })

    // Restore previous selection if it exists in the new options
    if (currentValue) {
      select.value = currentValue
    }

    select.disabled = false
  }

  clearModels() {
    const select = this.selectTarget
    
    // Clear all options except the first one (placeholder)
    while (select.children.length > 1) {
      select.removeChild(select.lastChild)
    }
    
    select.disabled = true
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'inline'
    }
    this.selectTarget.disabled = true
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'none'
    }
  }

  showError(message) {
    // You can customize this to show errors in your preferred way
    console.error('Model loading error:', message)
    
    // Optionally show an error message to the user
    const select = this.selectTarget
    const errorOption = document.createElement('option')
    errorOption.value = ''
    errorOption.textContent = `Error: ${message}`
    errorOption.disabled = true
    select.appendChild(errorOption)
  }
}
