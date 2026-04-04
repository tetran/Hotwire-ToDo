import { test, expect } from './fixtures/coverage'

test('未ログイン状態でログイン画面が表示される', async ({ page }) => {
  await page.goto('/')

  await expect(page).toHaveTitle('Hobo')

  await expect(page.getByRole('heading', { name: 'ログイン' })).toBeVisible()

  await expect(page.getByRole('textbox', { name: 'メールアドレス' })).toBeVisible()
  await expect(page.getByRole('textbox', { name: 'パスワード' })).toBeVisible()

  await expect(page.getByRole('button', { name: 'ログイン' })).toBeVisible()

  await expect(page.getByRole('link', { name: '新規登録' })).toBeVisible()
  await expect(page.getByRole('link', { name: 'パスワードをリセット' })).toBeVisible()
})
