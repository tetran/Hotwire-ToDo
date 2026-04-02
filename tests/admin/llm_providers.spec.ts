import { test, expect } from '../fixtures/coverage'

test.describe('Admin LLM プロバイダー管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })
  })

  test('LLM プロバイダー一覧が表示されること', async ({ page }) => {
    await page.goto('/admin/llm-providers')

    await expect(page.getByRole('heading', { name: 'LLM Providers' })).toBeVisible({ timeout: 10000 })

    // シードデータで作成されたプロバイダーが表示されること
    await expect(page.getByText('OpenAI')).toBeVisible()

    // Active バッジが表示されること
    await expect(page.locator('[data-testid="provider-card"]').first()).toBeVisible()
  })

  test('プロバイダー詳細が表示されること', async ({ page }) => {
    await page.goto('/admin/llm-providers')
    await expect(page.getByRole('heading', { name: 'LLM Providers' })).toBeVisible({ timeout: 10000 })

    // OpenAI の Detail リンクをクリック
    const openaiCard = page.locator('[data-testid="provider-card"]', { has: page.getByText('OpenAI') })
    await openaiCard.getByRole('link', { name: 'Detail' }).click()

    await expect(page).toHaveURL(/\/admin\/llm-providers\/\d+$/, { timeout: 10000 })
    await expect(page.getByRole('heading', { name: /LLM Provider: OpenAI/ })).toBeVisible({ timeout: 10000 })

    // 詳細情報が表示されること
    await expect(page.getByText('API Key')).toBeVisible()
    await expect(page.getByRole('rowheader', { name: 'Active' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Back to list' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Edit' })).toBeVisible()
  })
})
