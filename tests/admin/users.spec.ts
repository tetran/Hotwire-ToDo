import { test, expect } from '../fixtures/coverage'

test.describe('Admin ユーザー管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill('password')
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })
  })

  test('ユーザー一覧が表示されること', async ({ page }) => {
    await page.goto('/admin/users')

    await expect(page.getByRole('heading', { name: 'Users' })).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('link', { name: 'New User' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Email' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Name' })).toBeVisible()
  })

  test('ユーザーを新規作成できること', async ({ page }) => {
    const timestamp = Date.now()
    const newEmail = `e2e_test_${timestamp}@example.com`
    const newName = `E2E Test User ${timestamp}`

    await page.goto('/admin/users/new')

    await expect(page.getByRole('heading', { name: 'New User' })).toBeVisible({ timeout: 10000 })

    await page.locator('input[type="email"]').fill(newEmail)
    await page.locator('input[type="text"]').fill(newName)

    const passwordInputs = page.locator('input[type="password"]')
    await passwordInputs.nth(0).fill('password123')
    await passwordInputs.nth(1).fill('password123')

    await page.getByRole('button', { name: 'Create' }).click()

    await expect(page).toHaveURL('/admin/users', { timeout: 10000 })
    await expect(page.getByText(newEmail)).toBeVisible({ timeout: 10000 })
  })

  test('ユーザーを編集できること', async ({ page }) => {
    await page.goto('/admin/users')
    await expect(page.getByRole('heading', { name: 'Users' })).toBeVisible({ timeout: 10000 })

    // 最初の Edit リンクをクリック
    const editLinks = page.getByRole('link', { name: 'Edit' })
    await expect(editLinks.first()).toBeVisible({ timeout: 10000 })
    await editLinks.first().click()

    await expect(page.getByRole('heading', { name: 'Edit User' })).toBeVisible({ timeout: 10000 })
    await expect(page).toHaveURL(/\/admin\/users\/\d+\/edit/)

    // Name フィールドを更新
    const nameInput = page.locator('input[type="text"]')
    await nameInput.clear()
    const updatedName = `Updated User ${Date.now()}`
    await nameInput.fill(updatedName)

    await page.getByRole('button', { name: 'Update' }).click()

    await expect(page).toHaveURL('/admin/users', { timeout: 10000 })
    await expect(page.getByText(updatedName)).toBeVisible({ timeout: 10000 })
  })

  test('ユーザーを削除できること', async ({ page }) => {
    // 削除用ユーザーを作成する
    const timestamp = Date.now()
    const deleteEmail = `e2e_delete_${timestamp}@example.com`
    const deleteName = `E2E Delete User ${timestamp}`

    await page.goto('/admin/users/new')
    await page.locator('input[type="email"]').fill(deleteEmail)
    await page.locator('input[type="text"]').fill(deleteName)

    const passwordInputs = page.locator('input[type="password"]')
    await passwordInputs.nth(0).fill('password123')
    await passwordInputs.nth(1).fill('password123')
    await page.getByRole('button', { name: 'Create' }).click()
    await expect(page).toHaveURL('/admin/users', { timeout: 10000 })
    await expect(page.getByText(deleteEmail)).toBeVisible({ timeout: 10000 })

    // 作成したユーザーの行にある Delete ボタンをクリック
    const row = page.locator('tr', { has: page.getByText(deleteEmail) })
    page.on('dialog', dialog => dialog.accept())
    await row.getByRole('button', { name: 'Delete' }).click()

    await expect(page.getByText(deleteEmail)).not.toBeVisible({ timeout: 10000 })
  })
})
