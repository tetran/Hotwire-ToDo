import { test, expect, type Page } from '../fixtures/coverage'
import { TEST_PASSWORD } from '../fixtures/auth'

const DESKTOP_VIEWPORT = { width: 1280, height: 800 }
const MOBILE_VIEWPORT = { width: 500, height: 800 }

const SIDEBAR_SELECTOR = '#admin-sidebar'
const KEY_DESKTOP = 'admin.sidebar.desktop'
const KEY_MOBILE = 'admin.sidebar.mobile'

async function loginAsAdmin(page: Page): Promise<void> {
  await page.goto('/admin/login')
  await page.locator('input[type="email"]').fill('admin@example.com')
  await page.locator('input[type="password"]').fill(TEST_PASSWORD)
  await page.getByRole('button', { name: 'Login' }).click()
  await expect(page).toHaveURL('/admin', { timeout: 10000 })
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible({ timeout: 10000 })
}

async function clearSidebarStorage(page: Page): Promise<void> {
  await page.evaluate(({ d, m }) => {
    localStorage.removeItem(d)
    localStorage.removeItem(m)
  }, { d: KEY_DESKTOP, m: KEY_MOBILE })
}

async function sidebarWidth(page: Page): Promise<number> {
  const box = await page.locator(SIDEBAR_SELECTOR).boundingBox()
  return box?.width ?? 0
}

async function sidebarLeftEdge(page: Page): Promise<number> {
  const box = await page.locator(SIDEBAR_SELECTOR).boundingBox()
  return box?.x ?? Number.NEGATIVE_INFINITY
}

test.describe('Admin Sidebar — Desktop rail collapse/expand', () => {
  test.use({ viewport: DESKTOP_VIEWPORT })

  test('既定で expanded (220px)、chevron で rail (64px) に折り畳めて localStorage に永続化される', async ({ page }) => {
    await loginAsAdmin(page)
    await clearSidebarStorage(page)
    await page.reload()
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeVisible()

    expect(await sidebarWidth(page)).toBeCloseTo(220, -1)

    await page.getByRole('button', { name: 'Collapse sidebar' }).click()
    await expect.poll(() => sidebarWidth(page)).toBeCloseTo(64, -1)

    const stored = await page.evaluate((k) => localStorage.getItem(k), KEY_DESKTOP)
    expect(stored).toBe('collapsed')

    await page.reload()
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeVisible()
    expect(await sidebarWidth(page)).toBeCloseTo(64, -1)

    await page.getByRole('button', { name: 'Expand sidebar' }).click()
    await expect.poll(() => sidebarWidth(page)).toBeCloseTo(220, -1)
    expect(await page.evaluate((k) => localStorage.getItem(k), KEY_DESKTOP)).toBe('expanded')
  })

  test('rail 状態でナビアイテムにフォーカスを当てるとツールチップが表示される', async ({ page }) => {
    await loginAsAdmin(page)
    await page.evaluate(({ k }) => localStorage.setItem(k, 'collapsed'), { k: KEY_DESKTOP })
    await page.reload()
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeVisible()

    const dashboardLink = page.getByRole('link', { name: 'Dashboard' })
    await expect(dashboardLink).toHaveAttribute('aria-label', 'Dashboard')
    await dashboardLink.focus()
    // Visual-only tooltip span (aria-hidden); rendered always, opacity controlled by CSS group-focus-within.
    await expect(
      page.locator('span[aria-hidden="true"].pointer-events-none', { hasText: 'Dashboard' }).first()
    ).toBeVisible()
  })
})

test.describe('Admin Sidebar — Mobile drawer', () => {
  test.use({ viewport: MOBILE_VIEWPORT })

  test('既定で closed、ハンバーガーで開き、in-drawer ✕ で閉じる', async ({ page }) => {
    await loginAsAdmin(page)
    await clearSidebarStorage(page)
    await page.reload()

    // Default closed: no localStorage entry → 'closed' on mobile (off-canvas should not obscure content).
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeAttached()
    expect(await sidebarLeftEdge(page)).toBeLessThan(-100)

    await page.getByRole('button', { name: 'Open navigation menu' }).click()
    await expect.poll(() => sidebarLeftEdge(page)).toBeGreaterThanOrEqual(-10)

    await page.getByRole('button', { name: 'Close navigation', exact: true }).click()
    await expect.poll(() => sidebarLeftEdge(page)).toBeLessThan(-100)
  })

  test('Backdrop タップで drawer が閉じる', async ({ page }) => {
    await loginAsAdmin(page)
    await page.evaluate(({ k }) => localStorage.setItem(k, 'open'), { k: KEY_MOBILE })
    await page.reload()
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeVisible()
    expect(await sidebarLeftEdge(page)).toBeGreaterThanOrEqual(-10)

    // Backdrop covers viewport at z-30; drawer is at z-40 with width 256.
    // Click well to the right of the drawer.
    await page.mouse.click(450, 400)
    await expect.poll(() => sidebarLeftEdge(page)).toBeLessThan(-100)
  })

  test('Esc キーで drawer が閉じる', async ({ page }) => {
    await loginAsAdmin(page)
    await page.evaluate(({ k }) => localStorage.setItem(k, 'open'), { k: KEY_MOBILE })
    await page.reload()
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeVisible()
    expect(await sidebarLeftEdge(page)).toBeGreaterThanOrEqual(-10)

    await page.keyboard.press('Escape')
    await expect.poll(() => sidebarLeftEdge(page)).toBeLessThan(-100)
  })
})

test.describe('Admin Sidebar — Viewport transition', () => {
  test('mobile→desktop 遷移時に admin.sidebar.mobile の localStorage は変化しない', async ({ page }) => {
    await page.setViewportSize(MOBILE_VIEWPORT)
    await loginAsAdmin(page)
    await page.evaluate(({ k }) => localStorage.setItem(k, 'open'), { k: KEY_MOBILE })
    await page.reload()
    await expect(page.locator(SIDEBAR_SELECTOR)).toBeVisible()

    const before = await page.evaluate((k) => localStorage.getItem(k), KEY_MOBILE)
    expect(before).toBe('open')

    await page.setViewportSize(DESKTOP_VIEWPORT)

    // Wait for the matchMedia transition to take effect (sidebar leftEdge changes when isDesktop flips),
    // then assert the localStorage key was not mutated. Polling on a real DOM signal is more resilient
    // than a fixed sleep under CI load.
    await expect.poll(() => sidebarLeftEdge(page)).toBeGreaterThanOrEqual(0)

    const after = await page.evaluate((k) => localStorage.getItem(k), KEY_MOBILE)
    expect(after).toBe(before)
  })

  test('desktop→mobile live resize で localStorage の mobile state を復元する', async ({ page }) => {
    await page.setViewportSize(DESKTOP_VIEWPORT)
    await loginAsAdmin(page)
    await page.evaluate(({ k }) => localStorage.setItem(k, 'open'), { k: KEY_MOBILE })

    // No reload — simulate a live resize.
    await page.setViewportSize(MOBILE_VIEWPORT)
    await expect.poll(() => sidebarLeftEdge(page)).toBeGreaterThanOrEqual(-10)
  })
})
