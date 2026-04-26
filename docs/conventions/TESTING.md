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

レビュー依頼の前に `bin/rails test:all` を1回走らせて、ドメインをまたぐ予期せぬリグレッションを捕捉する。`test:all` は Rails 8 の `Rails::Command::TestCommand#all` (Thor) が intercept するビルトインコマンドで、`test/**/*_test.rb` にマッチする全ファイル（unit + system）を **単一プロセス** で実行する（サブプロセス分割ではない）。

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

## 並列起動と DB ファイル分離

別ターミナルで `bin/rails test:auth` と `bin/rails test:task` のように複数の `bin/rails test:*` を同時起動しても **`database is locked` で落ちない**。`test/test_helper.rb` が起動ごとに `storage/test_<pid>.sqlite3` を使うので、プロセス間で DB ファイルが衝突しない（Rails の `parallelize(workers:)` は同一プロセス内のワーカー DB しか分離しないため、本仕組みでプロセス間衝突を別途解消している）。

通常終了時は `at_exit` で `storage/test_<pid>.sqlite3*`（worker 用 `-1`/`-2`、SQLite の `-shm`/`-wal` 含む）が自動掃除される。**強制終了**（`kill -9`、OS crash 等）時は `at_exit` が走らず orphan が残るので、必要に応じて `rm -f storage/test_*.sqlite3*` で手動掃除する。

固定 DB パスを使いたい場合は `TEST_DATABASE_PATH` を export する:

```sh
TEST_DATABASE_PATH=storage/test.sqlite3 bin/rails test:auth   # 従来挙動（並列起動時は衝突する点に注意）
```

**注意**: `db:test:prepare` / `db:seed:replant` 等 `test_helper.rb` を読まない rake タスクは `TEST_DATABASE_PATH` を尊重しない。常にデフォルトの `storage/test.sqlite3` に作用する。

## Rails 8 `bin/rails test:*` の dispatch 罠

Rails 7+/8 では `bin/rails test:*` コマンドは **Rake をバイパスして `Rails::Command::TestCommand` (Thor) に直送される**。以下の地雷に注意。

### `lib/tasks/*.rake` の同名 task は dead code

`bin/rails test:all` は Thor の `TestCommand#all` が先に引き受けるため、`lib/tasks/test_suites.rake` で `task :all` を定義しても **rake task は一切発火しない**（過去に dead code として削除した事例あり: commit `6036e72`）。同名の `test:*` rake task を新規追加したくなったら、まず Thor 側に同名コマンドが存在しないか確認する。

ドメイン別スイート（`test:task`, `test:project` 等）は Thor 側にビルトインが無いため rake task として正常に動く。

### `bin/rails test:all` は single-process 実行

複数の `test:*` を dispatch しているように見えても、**実体は単一プロセスで `test/**/*_test.rb` 全ファイルを走らせる**。検証は簡単で、出力中の `Run options: --seed` の出現回数を数えればよい（1回なら single-process 確定）。

もし「unit → system を別サブプロセスで実行したい」要件があれば、`test:*` ではなく **別名の task**（例: `suite:full`）を定義して `sh "bin/rails test"` / `sh "bin/rails test:system"` を順次呼ぶ形にする必要がある。`test:*` 名前空間は Thor が intercept するため使えない。

### `bin/rails test test:system` はサイレント失敗

```sh
bin/rails test test:system   # ❌ system tests は走らない
```

Rails はこの `test:system` を **file-path / pattern 引数** として解釈する（task chain ではない）。マッチするテストファイルがなくても通常のテストスイートが成功すれば exit 0 で帰ってくるため、CI や手動実行で **system tests が走っていないことに気付けない**。

正しい呼び出し:

```sh
bin/rails test          # 非 system tests
bin/rails test:system   # system tests
bin/rails test:all      # 両方（単一プロセス、Thor ビルトイン）
```

## Non-Transactional Tests と FK 制約

`self.use_transactional_tests = false` を使っているテストは teardown で手動 `delete_all` が必要で、**FK 参照の依存順序を守らなければならない**（子テーブル → 親テーブルの順）。

**新しく FK 参照を持つテーブルを追加したら**:

1. `rg "use_transactional_tests = false" test/` で該当テストファイルを全て洗い出す
2. 新テーブルが FK 参照している先のテストの teardown に、新テーブルの `delete_all` を**参照先の `delete_all` より前**に追加する
3. ローカルの SQLite はデフォルトで FK 制約を強制しないため、ローカルで気づけず CI で爆発することがある。必ず grep して網羅する

過去に `events` テーブル追加時、4ファイル（`user_test`, `role_permission_test`, `user_role_test`, `suggestion_request_test`）への追加漏れで CI が 56 errors になった。
