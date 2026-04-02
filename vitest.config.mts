import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./app/javascript/admin/__tests__/setup.ts'],
    include: ['app/javascript/**/__tests__/**/*.test.{ts,tsx}'],
    typecheck: {
      tsconfig: './tsconfig.test.json',
    },
    coverage: {
      provider: 'v8',
      reportsDirectory: './coverage/frontend',
      reporter: ['text', 'html', 'lcov'],
      include: ['app/javascript/**/*.{ts,tsx}'],
      exclude: ['app/javascript/**/__tests__/**'],
    },
  },
  resolve: {
    alias: {
      '@admin': path.resolve(__dirname, 'app/javascript/admin'),
    },
  },
})
