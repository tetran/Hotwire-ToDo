import { test, expect } from '@playwright/test'

test.describe('Admin 認証フロー', () => {
  test('ログインページが表示されること', async ({ page }) => {
    await page.goto('/admin/login')

    await expect(page.getByRole('heading', { name: 'Admin Login' })).toBeVisible()
    await expect(page.getByText('Email')).toBeVisible()
    await expect(page.getByText('Password')).toBeVisible()
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible()
  })

  test('正しい認証情報でログインできること', async ({ page }) => {
    await page.goto('/admin/login')

    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()

    await expect(page).toHaveURL('/admin', { timeout: 10000 })
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible({ timeout: 10000 })
  })

  test('不正な認証情報でログインが失敗すること', async ({ page }) => {
    await page.goto('/admin/login')

    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('wrongpassword')
    await page.getByRole('button', { name: 'Login' }).click()

    await expect(page.locator('[data-testid="error-message"]')).toBeVisible({ timeout: 5000 })
    await expect(page).toHaveURL('/admin/login')
  })

  test('ログアウトできること', async ({ page }) => {
    // ログイン
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })

    // ログアウト
    await page.getByRole('button', { name: 'Logout' }).click()
    await expect(page).toHaveURL('/admin/login', { timeout: 10000 })
    await expect(page.getByRole('heading', { name: 'Admin Login' })).toBeVisible()
  })
})

test.describe('ナビゲーション capabilities フィルタリング', () => {
  test('user_viewer は Users ナビが表示され LLM Providers ナビが非表示', async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('viewer@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })

    await expect(page.getByRole('link', { name: 'Users' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'LLM Providers' })).not.toBeVisible()
  })

  test('llm_admin_user は LLM Providers ナビが表示され Users ナビが非表示', async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('llmadmin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })

    await expect(page.getByRole('link', { name: 'LLM Providers' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Users' })).not.toBeVisible()
  })

  test('user_viewer が /admin/llm-providers に直接アクセスすると Dashboard にリダイレクト', async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('viewer@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })

    await page.goto('/admin/llm-providers')
    await expect(page).toHaveURL('/admin', { timeout: 5000 })
  })

  test('llm_admin_user が /admin/roles/new に直接アクセスすると Dashboard にリダイレクト', async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('llmadmin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })

    await page.goto('/admin/roles/new')
    await expect(page).toHaveURL('/admin', { timeout: 5000 })
  })
})
