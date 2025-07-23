import { test, expect } from '@playwright/test';

test('未ログイン状態でログイン画面が表示される', async ({ page }) => {
  await page.goto('/');

  await expect(page).toHaveTitle('Hobo');

  await expect(page.getByRole('heading', { name: 'Login' })).toBeVisible();

  await expect(page.getByRole('textbox', { name: 'Email' })).toBeVisible();
  await expect(page.getByRole('textbox', { name: 'Password' })).toBeVisible();
  
  await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Sign up' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Reset password' })).toBeVisible();
});