# ユーザー管理機能

## 概要

Admin パネルからユーザーの CRUD 操作とロール割当を行えます。
自己削除防止とシステムロールの保護措置が設けられています。

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| `app/controllers/api/v1/admin/users_controller.rb` | User CRUD API |
| `app/controllers/api/v1/admin/user_roles_controller.rb` | ユーザーへのロール割当 API |
| `app/javascript/admin/pages/users/UsersIndexPage.tsx` | ユーザー一覧 |
| `app/javascript/admin/pages/users/UserNewPage.tsx` | ユーザー作成 |
| `app/javascript/admin/pages/users/UserEditPage.tsx` | ユーザー編集 |
| `app/javascript/admin/pages/users/UserRolePage.tsx` | ロール割当 |
| `test/controllers/api/v1/admin/users_controller_test.rb` | User CRUD テスト |
| `test/controllers/api/v1/admin/user_roles_controller_test.rb` | ロール割当テスト |

---

## User CRUD エンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/users` | `User:read` | ユーザー一覧（ロール情報付き） |
| `GET` | `/api/v1/admin/users/:id` | `User:read` | ユーザー詳細 |
| `POST` | `/api/v1/admin/users` | `User:write` | ユーザー作成 |
| `PATCH` | `/api/v1/admin/users/:id` | `User:write` | ユーザー更新（email / name） |
| `DELETE` | `/api/v1/admin/users/:id` | `User:delete` | ユーザー削除 |

### レスポンスフィールド

```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "User Name",
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

> `password` / `password_digest` はレスポンスに含まれません。

---

## ロール割当エンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/users/:user_id/roles` | `User:read` | ユーザーの現在のロール一覧 |
| `PATCH` | `/api/v1/admin/users/:user_id/roles` | `User:write` | ロールを同期（全量置換） |

### リクエスト形式（`PATCH`）

```json
{ "role_ids": [2, 3] }
```

空配列 `[]` を送ると、システムロール以外のすべてのロールを削除します。

---

## セキュリティ制約

### 自己削除防止

ログイン中の Admin 自身のアカウントは削除できません（`UsersController#destroy` で拒否）。

### システムロールの割当禁止

`system_role: true` のロールを API で割り当てることはできません。

```ruby
# UserRolesController#protect_system_role_assignment
return unless Role.exists?(id: role_ids_param, system_role: true)
render json: { error: "Forbidden" }, status: :forbidden
```

### システムロールの剥奪禁止

ユーザーが現在保持しているシステムロールを削除することもできません。

```ruby
# UserRolesController#protect_system_role_removal
removed = current_system_roles.reject { |r| new_role_ids.include?(r.id) }
render json: { error: "Forbidden" }, status: :forbidden if removed.any?
```

### 権限昇格防止

割り当てるロールが持つパーミッションが、操作者（current_admin）のパーミッションを超える場合は 403 になります。
詳細は [`docs/features/authorization.md`](authorization.md) を参照してください。

---

## HTTP レスポンスコード

| ステータス | 状況 |
|----------|------|
| `200 OK` | 取得 / 更新成功 |
| `201 Created` | ユーザー作成成功 |
| `204 No Content` | ユーザー削除成功 |
| `401 Unauthorized` | Admin セッションなし |
| `403 Forbidden` | 権限不足、自己削除試行、システムロール操作、権限昇格 |
| `404 Not Found` | 対象ユーザーが存在しない |
| `422 Unprocessable Entity` | バリデーションエラー |
