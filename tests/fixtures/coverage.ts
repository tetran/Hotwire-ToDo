import { test as base, expect } from '@playwright/test'
import { CoverageReport } from 'monocart-coverage-reports'

const coverageOptions = {
  outputDir: './coverage/e2e',
  reports: [
    ['v8'],
    ['lcov'],
    ['console-summary'],
  ],
  entryFilter: {
    '**/node_modules/**': false,
    '**/assets/**': true,
    '**/*': false,
  },
  sourceFilter: {
    '**/app/javascript/**': true,
    '**/*': false,
  },
}

const test = base.extend<{ autoCollectCoverage: void }>({
  autoCollectCoverage: [async ({ page, browserName }, use) => {
    const isChromium = browserName === 'chromium'

    if (isChromium) {
      await Promise.all([
        page.coverage.startJSCoverage({ resetOnNavigation: false }),
        page.coverage.startCSSCoverage({ resetOnNavigation: false }),
      ])
    }

    await use()

    if (isChromium) {
      const [jsCoverage, cssCoverage] = await Promise.all([
        page.coverage.stopJSCoverage(),
        page.coverage.stopCSSCoverage(),
      ])
      const coverageData = [...jsCoverage, ...cssCoverage]
      const mcr = new CoverageReport(coverageOptions)
      await mcr.add(coverageData)
    }
  }, { auto: true }],
})

export { test, expect }
