# パーミッション管理機能

## 概要

パーミッションはシステムで事前定義された読み取り専用のリソースです。
Admin UI では閲覧のみ可能で、作成・変更・削除はできません。
パーミッションをロールへ割り当てる操作は [ロール管理機能](role-management.md) で行います。

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| `app/controllers/api/v1/admin/permissions_controller.rb` | パーミッション一覧・詳細 API |
| `app/javascript/admin/pages/permissions/PermissionsIndexPage.tsx` | パーミッション一覧 |
| `app/javascript/admin/pages/permissions/PermissionDetailPage.tsx` | パーミッション詳細（割当済みロール付き） |
| `test/controllers/api/v1/admin/permissions_controller_test.rb` | パーミッションテスト |

---

## エンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/permissions` | `Admin:read`（全員） | パーミッション一覧 |
| `GET` | `/api/v1/admin/permissions/:id` | `Admin:read` | パーミッション詳細（割当済みロール付き） |

---

## パーミッションの構造

パーミッションは `ResourceType:Action` の組み合わせで定義されます。

### ResourceType

`User` / `Project` / `Task` / `Comment` / `Admin` / `LlmProvider`

### Action

`read` / `write` / `delete` / `manage`

### 全パーミッション一覧（例）

| id | resource_type | action | 説明 |
|----|-------------|--------|------|
| 1 | `User` | `read` | ユーザー一覧・詳細の閲覧 |
| 2 | `User` | `write` | ユーザーの作成・更新 |
| 3 | `User` | `delete` | ユーザーの削除 |
| 4 | `Admin` | `read` | Admin パネルへのアクセス（全員必須） |
| 5 | `LlmProvider` | `read` | LLM プロバイダー/モデルの閲覧 |
| 6 | `LlmProvider` | `write` | LLM プロバイダー/モデルの作成・更新 |
| 7 | `LlmProvider` | `delete` | LLM モデルの削除 |
| … | … | … | … |

実際の一覧は `GET /api/v1/admin/permissions` で確認するか、`db/seeds.rb` を参照してください。

---

## レスポンスフィールド

### 一覧（`GET /api/v1/admin/permissions`）

```json
[
  {
    "id": 1,
    "resource_type": "User",
    "action": "read",
    "description": "ユーザー一覧・詳細の閲覧"
  }
]
```

### 詳細（`GET /api/v1/admin/permissions/:id`）

```json
{
  "id": 1,
  "resource_type": "User",
  "action": "read",
  "description": "ユーザー一覧・詳細の閲覧",
  "roles": [
    { "id": 1, "name": "admin" },
    { "id": 2, "name": "user_manager" }
  ]
}
```

詳細エンドポイントはそのパーミッションを持つロール一覧も返します。

---

## HTTP レスポンスコード

| ステータス | 状況 |
|----------|------|
| `200 OK` | 取得成功 |
| `401 Unauthorized` | Admin セッションなし |
| `403 Forbidden` | `Admin:read` なし（通常あり得ない） |
| `404 Not Found` | 対象パーミッションが存在しない |
