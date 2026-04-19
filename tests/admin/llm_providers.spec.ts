import { test, expect } from '../fixtures/coverage'
import { TEST_PASSWORD } from '../fixtures/auth'

test.describe('Admin LLM プロバイダー管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill(TEST_PASSWORD)
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

  test('プロバイダー Workspace が表示されること', async ({ page }) => {
    await page.goto('/admin/llm-providers')
    await expect(page.getByRole('heading', { name: 'LLM Providers' })).toBeVisible({ timeout: 10000 })

    // OpenAI カード全体をクリック
    const openaiCard = page.locator('[data-testid="provider-card"]', { has: page.getByText('OpenAI') })
    await openaiCard.click()

    await expect(page).toHaveURL(/\/admin\/llm-providers\/\d+$/, { timeout: 10000 })
    await expect(page.getByRole('heading', { name: /LLM Provider: OpenAI/ })).toBeVisible({ timeout: 10000 })

    // 詳細情報が表示されること
    await expect(page.getByText('API Key')).toBeVisible()
    await expect(page.getByRole('rowheader', { name: 'Active' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Back to LLM Providers' })).toBeVisible()
    // Provider Info card の Edit ボタン (models テーブル行の Edit と区別するため testid を使用)
    await expect(page.getByTestId('workspace-provider-edit')).toBeVisible()
  })
})
