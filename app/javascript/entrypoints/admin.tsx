import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '../admin/styles/admin.css'
import App from '../admin/App'

const container = document.getElementById('admin-root')
if (container) {
  createRoot(container).render(
    <StrictMode>
      <App />
    </StrictMode>
  )
}
