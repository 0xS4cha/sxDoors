import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { MotionGlobalConfig } from 'motion/react'
import App from './App'
import './index.css'

if (import.meta.env.DEV && new URLSearchParams(window.location.search).has('static')) {
  MotionGlobalConfig.skipAnimations = true
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
