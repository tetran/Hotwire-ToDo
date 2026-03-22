import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from '../App'

const container = document.getElementById('admin-root')
if (container) {
  createRoot(container).render(
    <StrictMode>
      <App />
    </StrictMode>
  )
}
