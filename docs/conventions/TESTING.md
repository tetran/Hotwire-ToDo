# テスト規約

## テスト実行ポリシー

### 開発中: ドメイン別テストスイートを使う

開発中はフルテストスイートを走らせない。代わりに、変更範囲をカバーする**ドメイン別テストスイート**を使う。各スイートは密結合なモデル・コントローラ・サービスをひとまとめにしているので、無関係なテストを待たずに横断的な影響を捕捉できる。

利用可能なスイート:

| コマンド | ドメイン | カバー範囲 |
|---|---|---|
| `bin/rails test:task` | Task | Task, Comment, Event, TaskSeries モデル + 全 task コントローラ + event サービス |
| `bin/rails test:project` | Project | Project, ProjectMember モデル + project コントローラ |
| `bin/rails test:auth` | Auth | User モデル + sessions, passwords, email verification, TOTP コントローラ |
| `bin/rails test:suggestion` | Suggestion | Suggestion*, SuggestedTask, Prompt* モデル + suggestion サービス + suggestion コントローラ |
| `bin/rails test:admin` | Admin | Role, Permission, RolePermission, UserRole, AdminLoginHistory モデル + 全 admin API コントローラ + authorization concern |
| `bin/rails test:llm` | LLM | LlmModel, LlmProvider モデル + LLM クライアント + LLM サービス |
| `bin/rails test:all` | 全体 | `bin/rails test` + `bin/rails test:system`（レビュー依頼前のフルスイート実行用） |

変更が複数ドメインに跨る場合は、該当するスイートを複数実行する。

### レビュー依頼前: フルスイートを1回実行

レビュー依頼の前に `bin/rails test:all` を1回走らせて、ドメインをまたぐ予期せぬリグレッションを捕捉する。`test:all` は `bin/rails test`（system tests を除く全テスト）→ `bin/rails test:system`（ブラウザベースのシステムテスト）を順次、それぞれクリーンなサブプロセスで実行する。

- Standard Flow: `bin/rails test:all` を使う（system tests 含む）
- Lightweight Flow: `bin/rails test` のみで可（typo/小変更は system tests 不要）

### 実行するスイートの選び方

1. 変更がどのドメインに属するか特定する
2. そのドメインのスイートを実行する
3. 落ちたら修正して同じスイートを再実行する
4. PR 作成前にフルスイートを1回実行する

### テストスイートのメンテナンス

スイート定義は `lib/tasks/test_suites.rake` にある。新しいテストファイルを追加したら該当ドメインのスイートに追加する。新しいドメインを作ったら同じファイルに新スイートを追加し、本ドキュメントも更新する。

**⚠ 必ず `Rails::TestUnit::Runner.run_from_rake` を使うこと**（`.run` ではない）。`.run` は `at_exit` 経由でインプロセス実行するため、rake の `:environment` でプリロードされた Rails 環境がセッション/リクエスト処理を壊し、**全コントローラテストが一律 403 Forbidden** を返す症状になる。`run_from_rake` は `rails test` をサブプロセスとして起動するのでクリーンな環境で実行される。

症状の見分け方: テスト実行時間が異常に短い（例: 159テストが3.7秒 vs 正常時24秒）、かつ全コントローラテストが一律同一ステータス。

## Non-Transactional Tests と FK 制約

`self.use_transactional_tests = false` を使っているテストは teardown で手動 `delete_all` が必要で、**FK 参照の依存順序を守らなければならない**（子テーブル → 親テーブルの順）。

**新しく FK 参照を持つテーブルを追加したら**:

1. `rg "use_transactional_tests = false" test/` で該当テストファイルを全て洗い出す
2. 新テーブルが FK 参照している先のテストの teardown に、新テーブルの `delete_all` を**参照先の `delete_all` より前**に追加する
3. ローカルの SQLite はデフォルトで FK 制約を強制しないため、ローカルで気づけず CI で爆発することがある。必ず grep して網羅する

過去に `events` テーブル追加時、4ファイル（`user_test`, `role_permission_test`, `user_role_test`, `suggestion_request_test`）への追加漏れで CI が 56 errors になった。
