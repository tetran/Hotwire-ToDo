# LLM プロバイダー管理機能

## 概要

Admin パネルから LLM プロバイダーの設定管理と、プロバイダーに紐づくモデルの CRUD を行えます。
API キーはレスポンスに含まれず、データベース上で暗号化されます。

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| `app/controllers/api/v1/admin/llm_providers_controller.rb` | LLM プロバイダー一覧・詳細・更新 |
| `app/controllers/api/v1/admin/llm_models_controller.rb` | LLM モデル CRUD |
| `app/controllers/api/v1/admin/available_models_controller.rb` | 外部 API からモデル一覧を動的取得 |
| `app/javascript/admin/pages/llm-providers/LlmProvidersIndexPage.tsx` | プロバイダー一覧 |
| `app/javascript/admin/pages/llm-providers/LlmProviderDetailPage.tsx` | プロバイダー詳細 |
| `app/javascript/admin/pages/llm-providers/LlmProviderEditPage.tsx` | プロバイダー編集 |
| `app/javascript/admin/pages/llm-providers/LlmModelsIndexPage.tsx` | モデル一覧 |
| `app/javascript/admin/pages/llm-providers/LlmModelNewPage.tsx` | モデル作成 |
| `app/javascript/admin/pages/llm-providers/LlmModelEditPage.tsx` | モデル編集 |
| `test/controllers/api/v1/admin/llm_providers_controller_test.rb` | プロバイダーテスト |
| `test/controllers/api/v1/admin/llm_models_controller_test.rb` | モデルテスト |
| `test/controllers/api/v1/admin/available_models_controller_test.rb` | 外部 API 連携テスト |

---

## LLM プロバイダーエンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/llm_providers` | `LlmProvider:read` | プロバイダー一覧 |
| `GET` | `/api/v1/admin/llm_providers/:id` | `LlmProvider:read` | プロバイダー詳細 |
| `PATCH` | `/api/v1/admin/llm_providers/:id` | `LlmProvider:write` | プロバイダー更新 |

> プロバイダーの作成・削除は Admin UI からはできません（システム定義）。

### プロバイダーレスポンスフィールド

```json
{
  "id": 1,
  "name": "openai",
  "api_endpoint": "https://api.openai.com/v1",
  "organization_id": "org-xxxx",
  "active": true,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

> `api_key_encrypted` はレスポンスに **含まれません**。

### プロバイダー更新パラメータ

| パラメータ | 型 | 説明 |
|----------|---|------|
| `name` | string | プロバイダー名 |
| `api_endpoint` | string | API エンドポイント URL |
| `organization_id` | string | 組織 ID（オプション） |
| `active` | boolean | 有効/無効 |
| `api_key` | string | API キー（更新時のみ送信） |

---

## LLM モデルエンドポイント

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/llm_providers/:llm_provider_id/llm_models` | `LlmProvider:read` | モデル一覧 |
| `GET` | `/api/v1/admin/llm_providers/:llm_provider_id/llm_models/:id` | `LlmProvider:read` | モデル詳細 |
| `POST` | `/api/v1/admin/llm_providers/:llm_provider_id/llm_models` | `LlmProvider:write` | モデル作成 |
| `PATCH` | `/api/v1/admin/llm_providers/:llm_provider_id/llm_models/:id` | `LlmProvider:write` | モデル更新 |
| `DELETE` | `/api/v1/admin/llm_providers/:llm_provider_id/llm_models/:id` | `LlmProvider:delete` | モデル削除 |

### モデルレスポンスフィールド

```json
{
  "id": 1,
  "name": "gpt-4o",
  "display_name": "GPT-4o",
  "active": true,
  "default_model": false,
  "llm_provider_id": 1,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

---

## Available Models エンドポイント（外部 API 連携）

| メソッド | パス | 必要権限 | 説明 |
|---------|------|---------|------|
| `GET` | `/api/v1/admin/llm_providers/:llm_provider_id/available_models` | `LlmProvider:write` | 外部 API からモデル一覧を動的取得 |

このエンドポイントはプロバイダーの認証情報を使って外部の LLM API に問い合わせ、
利用可能なモデルの一覧をリアルタイムで返します。新モデルの追加時に使います。

```ruby
# app/controllers/api/v1/admin/available_models_controller.rb
models = ModelListService.fetch_models(
  @llm_provider.name,
  @llm_provider.api_key,
  organization_id: @llm_provider.organization_id,
)
render json: models
rescue LlmClient::ApiError => e
  render json: { error: e.message }, status: :bad_gateway
```

> 外部 API エラー時は `502 Bad Gateway` を返します。

---

## API キーの秘匿方針

- API キーはデータベース上で **暗号化して保存**（カラム名: `api_key_encrypted`）
- レスポンスには **一切含めない**（`except: :api_key_encrypted` で除外）
- 更新時にのみリクエストボディで受け取り、即座に暗号化して保存

---

## HTTP レスポンスコード

| ステータス | 状況 |
|----------|------|
| `200 OK` | 取得 / 更新成功 |
| `201 Created` | モデル作成成功 |
| `204 No Content` | モデル削除成功 |
| `401 Unauthorized` | Admin セッションなし |
| `403 Forbidden` | `LlmProvider:read` / `write` / `delete` 不足 |
| `404 Not Found` | 対象プロバイダーまたはモデルが存在しない |
| `422 Unprocessable Entity` | バリデーションエラー |
| `502 Bad Gateway` | 外部 LLM API へのリクエスト失敗 |
