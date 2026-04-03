import { test, expect } from '../fixtures/coverage'

test.describe('Admin アカウント管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })
  })

  test('管理アカウント一覧が表示されること', async ({ page }) => {
    await page.goto('/admin/admin-accounts')

    await expect(page.getByRole('heading', { name: 'Admin Accounts' })).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('columnheader', { name: 'User' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Role' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Actions' })).toBeVisible()
  })

  test('管理アカウントを新規作成できること', async ({ page }) => {
    const timestamp = Date.now()
    const newEmail = `e2e_admin_${timestamp}@example.com`
    const newName = `E2E Admin ${timestamp}`

    await page.goto('/admin/admin-accounts/new')

    await expect(page.getByRole('heading', { name: 'New Admin Account' })).toBeVisible({ timeout: 10000 })

    await page.locator('input[type="email"]').fill(newEmail)
    await page.locator('input[type="text"]').fill(newName)

    const passwordInputs = page.locator('input[type="password"]')
    await passwordInputs.nth(0).fill('password123')
    await passwordInputs.nth(1).fill('password123')

    // Select a role with admin access (user_viewer has Admin:read)
    await page.getByText('user_viewer').click()

    await page.getByRole('button', { name: 'Create' }).click()

    await expect(page).toHaveURL('/admin/admin-accounts', { timeout: 10000 })
    await expect(page.getByText(newEmail)).toBeVisible({ timeout: 10000 })
  })

  test('管理権限を剥奪できること', async ({ page }) => {
    // まず剥奪用の管理アカウントを作成
    const timestamp = Date.now()
    const revokeEmail = `e2e_revoke_${timestamp}@example.com`
    const revokeName = `E2E Revoke ${timestamp}`

    await page.goto('/admin/admin-accounts/new')
    await expect(page.getByRole('heading', { name: 'New Admin Account' })).toBeVisible({ timeout: 10000 })

    await page.locator('input[type="email"]').fill(revokeEmail)
    await page.locator('input[type="text"]').fill(revokeName)

    const passwordInputs = page.locator('input[type="password"]')
    await passwordInputs.nth(0).fill('password123')
    await passwordInputs.nth(1).fill('password123')

    await page.getByText('user_viewer').click()
    await page.getByRole('button', { name: 'Create' }).click()

    await expect(page).toHaveURL('/admin/admin-accounts', { timeout: 10000 })
    await expect(page.getByText(revokeEmail)).toBeVisible({ timeout: 10000 })

    // 作成したアカウントの行にある Revoke ボタンをクリック
    const row = page.locator('tr', { has: page.getByText(revokeEmail) })
    page.on('dialog', dialog => dialog.accept())
    await row.getByRole('button', { name: 'Revoke' }).click()

    await expect(page.getByText(revokeEmail)).not.toBeVisible({ timeout: 10000 })
  })
})
