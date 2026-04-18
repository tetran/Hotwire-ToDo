import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '../admin/styles/admin.css'
import App from '../admin/App'
import { initSentry } from '../admin/lib/sentry'

initSentry()

const container = document.getElementById('admin-root')
if (container) {
  createRoot(container).render(
    <StrictMode>
      <App />
    </StrictMode>
  )
}
