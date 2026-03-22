import { test, expect } from '@playwright/test'

test.describe('Admin ロール管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })
  })

  test('ロール一覧が表示されること', async ({ page }) => {
    await page.goto('/admin/roles')

    await expect(page.getByRole('heading', { name: 'Roles' })).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('button', { name: 'New Role' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Name' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Actions' })).toBeVisible()
  })

  test('ロールを新規作成できること', async ({ page }) => {
    const timestamp = Date.now()
    const roleName = `e2e_role_${timestamp}`

    await page.goto('/admin/roles')
    await expect(page.getByRole('heading', { name: 'Roles' })).toBeVisible({ timeout: 10000 })

    await page.getByRole('button', { name: 'New Role' }).click()
    await expect(page).toHaveURL('/admin/roles/new', { timeout: 10000 })
    await expect(page.getByRole('heading', { name: 'New Role' })).toBeVisible()

    await page.locator('input[type="text"]').fill(roleName)
    await page.locator('textarea').fill('E2E test role description')

    await page.getByRole('button', { name: 'Create Role' }).click()

    await expect(page).toHaveURL('/admin/roles', { timeout: 10000 })
    await expect(page.getByText(roleName)).toBeVisible({ timeout: 10000 })
  })

  test('ロールを削除できること', async ({ page }) => {
    // 削除用ロールを作成する
    const timestamp = Date.now()
    const roleName = `e2e_delete_role_${timestamp}`

    await page.goto('/admin/roles/new')
    await page.locator('input[type="text"]').fill(roleName)
    await page.getByRole('button', { name: 'Create Role' }).click()
    await expect(page).toHaveURL('/admin/roles', { timeout: 10000 })
    await expect(page.getByText(roleName)).toBeVisible({ timeout: 10000 })

    // 作成したロールの行にある Delete ボタンをクリック
    const row = page.locator('tr', { has: page.getByText(roleName) })
    page.on('dialog', dialog => dialog.accept())
    await row.getByRole('button', { name: 'Delete' }).click()

    await expect(page.getByText(roleName)).not.toBeVisible({ timeout: 10000 })
  })
})
