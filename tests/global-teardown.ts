import { CoverageReport } from 'monocart-coverage-reports'

async function globalTeardown() {
  const mcr = new CoverageReport({
    outputDir: './coverage/e2e',
    reports: [
      ['v8'],
      ['lcov'],
      ['console-summary'],
    ],
  })
  await mcr.generate()
}

export default globalTeardown
