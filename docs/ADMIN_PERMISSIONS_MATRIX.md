# 管理者権限マトリクス

## 概要

この文書は、管理者インターフェース（`/admin`）で利用可能な機能と、それらの機能にアクセスするために必要な権限を定義しています。

## 権限システム

### リソースタイプ
- `Admin` - 管理者機能へのアクセス
- `User` - ユーザー管理機能
- `Project` - プロジェクト管理機能
- `Task` - タスク管理機能
- `Comment` - コメント管理機能

### アクション
- `read` - 閲覧権限
- `write` - 作成・更新権限
- `delete` - 削除権限
- `manage` - 全ての権限（read、write、deleteを含む）

### 権限継承
- `manage` 権限は他の全ての権限を含む
- 各アクションは対応する権限または `manage` 権限で実行可能

## 管理者機能権限マトリクス

| 機能 | 必要な権限 | 説明 |
|------|-----------|------|
| **管理者エリアアクセス** | `Admin:read` | 管理者エリア全体へのアクセス |
| **ダッシュボード** | `Admin:read` | 統計情報の閲覧 |

### ユーザー管理

| 機能 | 必要な権限 | 説明 |
|------|-----------|------|
| ユーザー一覧表示 | `User:read` | ユーザー一覧の閲覧、検索 |
| ユーザー詳細表示 | `User:read` | 個別ユーザー情報の閲覧 |
| ユーザー作成 | `User:write` | 新規ユーザーの作成 |
| ユーザー編集 | `User:write` | ユーザー情報の更新 |
| ユーザー削除 | `User:delete` | ユーザーの削除 |
| ユーザーロール管理 | `User:write` | ユーザーへのロール割り当て |

### ロール管理

| 機能 | 必要な権限 | 説明 |
|------|-----------|------|
| ロール一覧表示 | `User:read` | システムロールとカスタムロールの一覧 |
| ロール詳細表示 | `User:read` | 個別ロール情報と権限の閲覧 |
| カスタムロール作成 | `User:write` | 新規カスタムロールの作成 |
| ロール編集 | `User:write` | ロール情報の更新（システムロールは制限あり） |
| カスタムロール削除 | `User:delete` | カスタムロールの削除（システムロールは不可） |
| ロール権限管理 | `User:write` | ロールへの権限割り当て |

### 権限管理

| 機能 | 必要な権限 | 説明 |
|------|-----------|------|
| 権限一覧表示 | `User:read` | 全権限の一覧表示（リソースタイプ別） |
| 権限詳細表示 | `User:read` | 個別権限の詳細とロール割り当て状況 |

### LLM管理

| 機能 | 必要な権限 | 説明 |
|------|-----------|------|
| LLMプロバイダー一覧 | `Admin:read` | LLM プロバイダーの一覧表示 |
| LLMプロバイダー詳細 | `Admin:read` | プロバイダー詳細とモデル一覧 |
| LLMプロバイダー作成 | `Admin:read` | 新規プロバイダーの作成 |
| LLMプロバイダー編集 | `Admin:read` | プロバイダー情報の更新 |
| LLMプロバイダー削除 | `Admin:read` | プロバイダーの削除（使用中は不可） |
| LLMモデル一覧 | `Admin:read` | プロバイダー配下のモデル一覧 |
| LLMモデル詳細 | `Admin:read` | モデルの詳細情報 |
| LLMモデル作成 | `Admin:read` | 新規モデルの作成 |
| LLMモデル編集 | `Admin:read` | モデル情報の更新 |
| LLMモデル削除 | `Admin:read` | モデルの削除（使用中は不可） |

## システムロール

システムには以下の定義済みロールが存在します：

### admin
- 全ての権限を持つ最高権限ロール
- 通常、`Admin:manage`、`User:manage` などの管理権限を持つ

### user_manager
- ユーザー管理に特化したロール
- `User:read`、`User:write`、`User:delete` を持つ

### user_viewer
- ユーザー情報の閲覧のみ可能なロール
- `User:read` と `Admin:manage` を持つ

### project_manager
- プロジェクトとタスク管理に特化したロール
- `Project:manage`、`Task:manage`、`Comment:manage`、`Admin:manage` を持つ

## セキュリティ制限

### システムロール保護
- システムロール（`system_role: true`）は削除不可
- システムロールの名前と説明は変更不可
- 権限の割り当ては変更可能

### 使用中リソース保護
- 使用中のLLMプロバイダー・モデルは削除不可
- 関連するsuggestion requestsが存在する場合は削除をブロック

### 権限継承
- `manage` 権限は対応する `read`、`write`、`delete` 権限を自動的に含む
- より細かい権限制御が必要な場合は個別のアクション権限を使用

## アクセスパターン

1. **管理者エリアアクセス**: 全ての管理者機能は `Admin:read` が必要
2. **ユーザー・ロール管理**: `User` リソースの権限が必要
3. **LLM管理**: `Admin:read` のみで全機能が利用可能
4. **権限管理**: 権限の閲覧は `User:read`、権限の変更は `User:write` が必要

## TODO: 実装の不整合

> **注意**: 以下の問題は [Issue #121](https://github.com/tetran/Hotwire-ToDo/issues/121) で修正予定です。

### 権限チェック不足
以下のコントローラーで権限チェックが実装されていません：
- `app/controllers/admin/user_roles_controller.rb` - ユーザーロール管理
- `app/controllers/admin/role_permissions_controller.rb` - ロール権限管理

これらのコントローラーは基本的な管理者アクセス（`Admin:read`）はチェックしていますが、具体的な機能レベルでの権限チェック（`User:write`など）が不足しています。

### 権限マトリクスの修正
上記の不整合により、実際の実装では：
- **ユーザーロール管理**: `Admin:read` のみ必要（ドキュメントでは `User:write`）
- **ロール権限管理**: `Admin:read` のみ必要（ドキュメントでは `User:write`）

## 実装ファイル

- `app/controllers/admin/application_controller.rb` - 基本認証
- `app/controllers/concerns/authorization.rb` - 権限チェックロジック
- `app/models/user.rb` - ユーザー権限メソッド
- `app/models/permission.rb` - 権限モデル
- `app/models/role.rb` - ロールモデル
- `db/seeds.rb` - システムロールとデフォルト権限の定義