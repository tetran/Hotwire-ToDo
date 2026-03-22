# 管理者権限マトリクス

## 概要

この文書は、管理者インターフェース（`/admin`）で利用可能な機能と、それらの機能にアクセスするために必要な権限を定義しています。

## 権限システム

### リソースタイプ

- `Admin` - 管理者エリアへのアクセスゲート（`read` のみ有効）
- `User` - ユーザー管理機能
- `Project` - プロジェクト管理機能
- `Task` - タスク管理機能
- `Comment` - コメント管理機能
- `LlmProvider` - LLMプロバイダー・モデル管理機能

### アクション

- `read` - 閲覧権限
- `write` - 作成・更新権限
- `delete` - 削除権限
- `manage` - 全ての権限（read、write、deleteを含む）

### 権限継承

- `manage` 権限は他の全ての権限を含む
- 各アクションは対応する権限または `manage` 権限で実行可能

## 管理者機能権限マトリクス

| 機能                     | 必要な権限   | 説明                         |
| ------------------------ | ------------ | ---------------------------- |
| **管理者エリアアクセス** | `Admin:read` | 管理者エリア全体へのアクセス |
| **ダッシュボード**       | `Admin:read` | 統計情報の閲覧               |

### ユーザー管理

| 機能               | 必要な権限                   | 説明                                                   |
| ------------------ | ---------------------------- | ------------------------------------------------------ |
| ユーザー一覧表示   | `Admin:read` + `User:read`   | ユーザー一覧の閲覧、検索                               |
| ユーザー詳細表示   | `Admin:read` + `User:read`   | 個別ユーザー情報の閲覧                                 |
| ユーザー作成       | `Admin:read` + `User:write`  | 新規ユーザーの作成                                     |
| ユーザー編集       | `Admin:read` + `User:write`  | ユーザー情報の更新                                     |
| ユーザー削除       | `Admin:read` + `User:delete` | ユーザーの削除                                         |
| ユーザーロール表示 | `Admin:read` + `User:read`   | ユーザーへのロール割り当て状況閲覧                     |
| ユーザーロール管理 | `Admin:read` + `User:write`  | ユーザーへのロール割り当て（権限昇格防止制約あり）     |

### ロール管理

| 機能               | 必要な権限                   | 説明                                         |
| ------------------ | ---------------------------- | -------------------------------------------- |
| ロール一覧表示     | `Admin:read`                 | システムロールとカスタムロールの一覧         |
| ロール詳細表示     | `Admin:read`                 | 個別ロール情報と権限の閲覧                   |
| カスタムロール作成 | `admin` ロール限定           | 新規カスタムロールの作成                     |
| ロール編集         | `admin` ロール限定           | ロール情報の更新（システムロールは制限あり） |
| カスタムロール削除 | `admin` ロール限定           | カスタムロールの削除（システムロールは不可） |
| ロール権限表示     | `Admin:read`                 | ロールへの権限割り当て状況閲覧               |
| ロール権限管理     | `admin` ロール限定           | ロールへの権限割り当て                       |

### 権限管理

| 機能         | 必要な権限   | 説明                                 |
| ------------ | ------------ | ------------------------------------ |
| 権限一覧表示 | `Admin:read` | 全権限の一覧表示（リソースタイプ別） |
| 権限詳細表示 | `Admin:read` | 個別権限の詳細とロール割り当て状況   |

### LLM管理

| 機能                | 必要な権限                          | 説明                         |
| ------------------- | ----------------------------------- | ---------------------------- |
| LLMプロバイダー一覧 | `Admin:read` + `LlmProvider:read`   | LLM プロバイダーの一覧表示   |
| LLMプロバイダー詳細 | `Admin:read` + `LlmProvider:read`   | プロバイダー詳細とモデル一覧 |
| LLMプロバイダー編集 | `Admin:read` + `LlmProvider:write`  | プロバイダー情報の更新       |
| LLMモデル一覧       | `Admin:read` + `LlmProvider:read`   | プロバイダー配下のモデル一覧 |
| LLMモデル詳細       | `Admin:read` + `LlmProvider:read`   | モデルの詳細情報             |
| LLMモデル作成       | `Admin:read` + `LlmProvider:write`  | 新規モデルの作成             |
| LLMモデル編集       | `Admin:read` + `LlmProvider:write`  | モデル情報の更新             |
| LLMモデル削除       | `Admin:read` + `LlmProvider:delete` | モデルの削除（使用中は不可） |

## システムロール

システムには以下の定義済みロールが存在します：

### admin

- 全ての権限を持つ最高権限ロール
- 全リソースタイプの全アクション権限を持つ
- ロール・権限管理操作はこのロール保有者のみ実行可能

### user_manager

- ユーザー管理に特化したロール
- `Admin:read`、`User:read`、`User:write`、`User:delete` を持つ

### user_viewer

- ユーザー情報の閲覧のみ可能なロール
- `Admin:read`、`User:read` を持つ

### project_manager

- プロジェクトとタスク管理に特化したロール
- `Admin:read`、`Project:manage`、`Task:manage`、`Comment:manage` を持つ

### llm_admin

- LLM設定管理に特化したロール
- `Admin:read`、`LlmProvider:read`、`LlmProvider:write`、`LlmProvider:delete` を持つ

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

### 権限昇格防止

- ユーザーロール割り当て時、自身が持つ権限の範囲内のロールのみ割り当て可能
- ロール権限割り当ては `admin` ロール保有者のみ実行可能

### Admin リソースについて

- `Admin` リソースは `read` アクションのみ有効
- `Admin:read` は管理者エリアへの入場ゲートとして機能し、全管理者機能の前提条件
- ロール・権限のメタ管理操作はパーミッションシステムではなく `admin` ロール保有者チェックで制御する

## アクセスパターン

1. **管理者エリアアクセス**: 全ての管理者機能は `Admin:read` が必要
2. **ユーザー管理**:
   - 閲覧: `Admin:read` + `User:read`
   - 作成・編集・ロール割り当て: `Admin:read` + `User:write`
   - 削除: `Admin:read` + `User:delete`
3. **ロール・権限管理**:
   - 閲覧: `Admin:read`
   - 作成・編集・削除・権限割り当て: `admin` ロール限定
4. **LLM管理**:
   - 閲覧: `Admin:read` + `LlmProvider:read`
   - 作成・編集: `Admin:read` + `LlmProvider:write`
   - 削除: `Admin:read` + `LlmProvider:delete`

## 実装ファイル

- `app/controllers/api/v1/admin/application_controller.rb` - 基本認証・権限チェックヘルパー
- `app/controllers/api/v1/admin/` - 各リソースの API コントローラー
- `app/controllers/concerns/authorization.rb` - 権限チェックロジック
- `app/models/user.rb` - ユーザー権限メソッド（`can_read?`、`can_write?` 等）
- `app/models/permission.rb` - 権限モデル
- `app/models/role.rb` - ロールモデル
- `db/seeds.rb` - システムロールとデフォルト権限の定義
