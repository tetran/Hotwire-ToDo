# Admin Interface Specification

`/admin` 管理インターフェースが備える機能の一覧です。

## アーキテクチャ概要

管理画面は **React SPA** として実装されています。

- **SPA シェル**: `AdminController#index` が `<div id="admin-root"></div>` のみを返す
- **フロントエンド**: React + TypeScript（`app/javascript/admin/`）
- **API**: JSON REST API（`/api/v1/admin/` 名前空間）
- **ルーティング**: React Router による クライアントサイドルーティング
- **スタイル**: Tailwind CSS v4

---

## 1. ダッシュボード (`/admin/`)

システム全体の統計情報を表示：

- 総ユーザー数・プロジェクト数・タスク数・未完了タスク数
- 最近のユーザー（直近5件）
- 最近のプロジェクト（直近5件）

---

## 2. ユーザー管理 (`/admin/users`)

| 操作 | 説明 |
|------|------|
| 一覧・検索 | email / 氏名で絞り込み |
| 作成 | email・氏名・タイムゾーン・ロケール・パスワード |
| 編集 (`/admin/users/:id/edit`) | パスワード以外のすべてのフィールド |
| 削除 | 完全削除（force_destroy） |

---

## 3. ロール管理 (`/admin/roles`)

| 操作 | 備考 |
|------|------|
| 一覧 | システムロール / カスタムロールを分けて表示 |
| 作成 (`/admin/roles/new`) | 名称・説明を設定 |
| 編集 (`/admin/roles/:id/edit`) | カスタムロールは全項目、システムロールは権限のみ変更可 |
| 削除 | システムロールは削除不可 |

---

## 4. 権限管理 (`/admin/permissions`)

**読み取り専用**（作成・編集・削除なし）：

- 一覧: リソース種別ごとにグループ化して表示
- 詳細 (`/admin/permissions/:id`): 各権限に紐づくロールを確認可能

---

## 5. ユーザー↔ロール 紐付け (`/admin/users/:id/roles`)

- ユーザーへのロール一括割り当て・解除

---

## 6. ロール↔権限 紐付け (`/admin/roles/:id/permissions`)

- ロールへの権限一括割り当て・解除
- リソース種別ごとにグループ化して表示

---

## 7. LLM プロバイダー管理 (`/admin/llm-providers`)

| 操作 | 備考 |
|------|------|
| 一覧 | プロバイダー名・API エンドポイント・モデル数・ステータス |
| 詳細 (`/admin/llm-providers/:id`) | プロバイダー情報 + 紐づくモデル一覧 |
| 編集 (`/admin/llm-providers/:id/edit`) | API エンドポイント・API キー・Organization ID・有効/無効フラグ |

- 作成・削除は不可（プリセット設定のみ）
- API キーはブランクで送信しても既存値を保持

---

## 8. LLM モデル管理 (`/admin/llm-providers/:id/models`)

| 操作 | 備考 |
|------|------|
| 一覧 | 名称・表示名・デフォルト・有効状態・使用数 |
| 作成 (`/admin/llm-providers/:id/models/new`) | name・display_name・active・default_model |
| 編集 (`/admin/llm-providers/:id/models/:modelId/edit`) | 全フィールド |
| 削除 | suggestion_requests で使用中のモデルは削除不可 |

---

## 9. 利用可能モデル取得 (API only)

- `GET /api/v1/admin/llm_providers/:id/available_models`
- プロバイダーの API を叩いて利用可能なモデル一覧を JSON で返す
- API キーが未設定の場合はエラーを返す

---

## 認可モデル

詳細は [ADMIN_PERMISSIONS_MATRIX.md](ADMIN_PERMISSIONS_MATRIX.md) を参照。
