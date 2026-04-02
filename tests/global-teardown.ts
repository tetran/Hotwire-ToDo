import { CoverageReport } from 'monocart-coverage-reports'
import { coverageOptions } from './fixtures/coverage'

async function globalTeardown() {
  const mcr = new CoverageReport(coverageOptions)

  if (mcr.hasCache()) {
    await mcr.generate()
  }
}

export default globalTeardown
