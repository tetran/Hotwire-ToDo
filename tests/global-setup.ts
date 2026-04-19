import { execSync } from 'node:child_process'

async function globalSetup() {
  execSync('bin/rails db:prepare db:seed', {
    stdio: 'inherit',
    env: { ...process.env, RAILS_ENV: 'test' },
  })
}

export default globalSetup
