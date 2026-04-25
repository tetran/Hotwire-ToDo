import { test, expect } from '../fixtures/coverage'
import { TEST_PASSWORD } from '../fixtures/auth'

test.describe('Admin ユーザー管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/login')
    await page.locator('input[type="email"]').fill('admin@example.com')
    await page.locator('input[type="password"]').fill(TEST_PASSWORD)
    await page.getByRole('button', { name: 'Login' }).click()
    await expect(page).toHaveURL('/admin', { timeout: 10000 })
  })

  test('ユーザー一覧が表示されること', async ({ page }) => {
    await page.goto('/admin/users')

    await expect(page.getByRole('heading', { name: 'Users' })).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('columnheader', { name: 'User' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Created At' })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: 'Actions' })).toBeVisible()
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
    await passwordInputs.nth(0).fill(TEST_PASSWORD)
    await passwordInputs.nth(1).fill(TEST_PASSWORD)

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

  test('ユーザーを退会させられること', async ({ page }) => {
    // 退会対象ユーザーを作成する
    const timestamp = Date.now()
    const deactivateEmail = `e2e_deactivate_${timestamp}@example.com`
    const deactivateName = `E2E Deactivate User ${timestamp}`

    await page.goto('/admin/users/new')
    await page.locator('input[type="email"]').fill(deactivateEmail)
    await page.locator('input[type="text"]').fill(deactivateName)

    const passwordInputs = page.locator('input[type="password"]')
    await passwordInputs.nth(0).fill(TEST_PASSWORD)
    await passwordInputs.nth(1).fill(TEST_PASSWORD)
    await page.getByRole('button', { name: 'Create' }).click()
    await expect(page).toHaveURL('/admin/users', { timeout: 10000 })
    await expect(page.getByText(deactivateEmail)).toBeVisible({ timeout: 10000 })

    // 作成したユーザーの行にある Deactivate ボタンをクリック
    const row = page.locator('tr', { has: page.getByText(deactivateEmail) })
    await row.getByRole('button', { name: 'Deactivate' }).click()

    // 確認モーダルで Deactivate を確定
    const dialog = page.getByRole('dialog', { name: 'Deactivate User' })
    await expect(dialog).toBeVisible({ timeout: 5000 })
    await dialog.getByRole('button', { name: 'Deactivate' }).click()

    // active フィルタ (デフォルト) では退会済みユーザーは一覧から外れる
    await expect(page.getByText(deactivateEmail)).not.toBeVisible({ timeout: 10000 })
  })
})
