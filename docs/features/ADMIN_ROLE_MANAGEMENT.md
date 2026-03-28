# ロール管理機能

## 概要

Admin パネルからロールの CRUD 操作とパーミッション割当を行えます。
システムロールは変更・削除が禁止されており、権限昇格を防ぐ制約があります。
ロール管理操作は `is_admin` フラグ（full admin）のみが実行できます（ケイパビリティによる委任不可）。

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| `app/controllers/api/v1/admin/roles_controller.rb` | Role CRUD API |
| `app/controllers/api/v1/admin/role_permissions_controller.rb` | ロールへのパーミッション割当 API |
| `app/javascript/admin/pages/roles/RolesIndexPage.tsx` | ロール一覧 |
| `app/javascript/admin/pages/roles/RoleNewPage.tsx` | ロール作成 |
| `app/javascript/admin/pages/roles/RoleEditPage.tsx` | ロール編集 |
| `app/javascript/admin/pages/roles/RolePermissionPage.tsx` | パーミッション割当 |
| `test/controllers/api/v1/admin/roles_controller_test.rb` | Role CRUD テスト |
| `test/controllers/api/v1/admin/role_permissions_controller_test.rb` | パーミッション割当テスト |

---

## Role CRUD エンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/roles` | `Admin:read`（全員） | ロール一覧 |
| `GET` | `/api/v1/admin/roles/:id` | `Admin:read` | ロール詳細（パーミッション付き） |
| `POST` | `/api/v1/admin/roles` | `require_manage_access`（is_admin のみ） | ロール作成 |
| `PATCH` | `/api/v1/admin/roles/:id` | `require_manage_access` | ロール更新 |
| `DELETE` | `/api/v1/admin/roles/:id` | `require_manage_access` | ロール削除 |

### レスポンスフィールド

```json
{
  "id": 5,
  "name": "llm_viewer",
  "description": "LLM プロバイダーの閲覧のみ",
  "system_role": false,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

---

## パーミッション割当エンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/roles/:role_id/permissions` | `Admin:read` | ロールのパーミッション一覧 |
| `PATCH` | `/api/v1/admin/roles/:role_id/permissions` | `require_manage_access` | パーミッションを同期（全量置換） |

### リクエスト形式（`PATCH`）

```json
{ "permission_ids": [1, 2, 3] }
```

---

## セキュリティ制約

### システムロールの保護

`system_role: true` のロールは更新・削除・パーミッション変更がすべて禁止されています。

```ruby
# RolesController: system_role への更新・削除を拒否
render json: { error: "Forbidden" }, status: :forbidden if @role.system_role?
```

### `system_role` パラメータの無視

ロールの作成・更新時に `system_role` パラメータを送っても、サーバー側で無視されます（昇格防止）。

### 権限昇格防止

割り当てようとするパーミッションが、操作者（current_admin）が持つパーミッションを超える場合は 403 になります。

```ruby
# RolePermissionsController#protect_permission_escalation
new_ids = permission_ids_param.compact_blank.map(&:to_i)
admin_ids = current_admin.roles.joins(:permissions).pluck("permissions.id").uniq
return if (new_ids - admin_ids).empty?
render json: { error: "Forbidden" }, status: :forbidden
```

詳細は [`docs/features/authorization.md`](authorization.md) を参照してください。

---

## システムロール一覧

| ロール名 | 説明 |
|---------|------|
| `admin` | すべてのリソースへのフルアクセス |
| `user_manager` | User:read / User:write / User:delete（ユーザー管理専用） |

---

## HTTP レスポンスコード

| ステータス | 状況 |
|----------|------|
| `200 OK` | 取得 / 更新成功 |
| `201 Created` | ロール作成成功 |
| `204 No Content` | ロール削除成功 |
| `401 Unauthorized` | Admin セッションなし |
| `403 Forbidden` | `is_admin` でない、システムロール操作、権限昇格 |
| `404 Not Found` | 対象ロールが存在しない |
| `422 Unprocessable Entity` | バリデーションエラー |
