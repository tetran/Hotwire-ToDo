# Event Tracking — 設計知見

Issue #10 で導入したイベント追跡機能（`events` テーブル + `Events::Recorder`）を実装する際に得られた、繰り返し参照したい設計上の知見をまとめる。機能の全体像は `docs/features/` 側を参照し、このドキュメントは「なぜそう書いてあるか」の意図を残すことを目的とする。

---

## 1. FK 制約と監査ログの相性

`events` テーブルに `belongs_to :task, foreign_key: true` 等を付けると、参照先（task, project, user）を削除するときに `ActiveRecord::InvalidForeignKey` で業務操作がブロックされる。

`null: false` + `on_delete: :nullify` は**矛盾する**（削除時に NULL を入れようとして NOT NULL 制約違反になる）。

**SQLite の罠**: SQLite はデフォルトで FK を強制しないため、ローカルでは問題なく動いてしまい、PostgreSQL/MySQL の本番で初めて壊れる。

**対処方針は二択**:
- 参照先の削除を禁止する（業務上許容できる場合）
- 該当カラムを nullable にする（`null: true` + `on_delete: :nullify`）

## 2. `saved_changes` のキャプチャタイミング

`Tasks::Updater` のように transaction 内で複数の `update` が連続する場合、最初の `update` の `saved_changes` は**後続の `update` で上書きされる**。

変更内容を正確に記録するには:

```ruby
ActiveRecord::Base.transaction do
  task.update!(attrs)
  changes = task.saved_changes.dup  # ← 直後にキャプチャして dup
  # ... 他の update が続く ...
end

# イベント記録は transaction 外で実行する
Events::Recorder.call(task:, changes:)
```

## 3. イベント記録はエラーで業務をブロックしない

イベント記録は可観測性機能であり、**業務操作をブロックしてはならない**。`Events::Recorder` では `rescue StandardError` で例外を握りつぶし、`Rails.logger.error` で記録する。

さらに、**transaction 内でイベントを記録しない**。記録失敗時にロールバックが発生するリスクがあるため、必ず transaction の外で呼ぶ。

## 4. destroy 済みレコードのイベント記録

`destroy!` した後のオブジェクトは属性（`id`, `name` 等）にアクセスはできるが、FK 参照としては使えない（レコードが存在しないため制約違反）。

削除イベントを記録する場合:

```ruby
# ❌ BAD: task は既に destroy 済み → FK 違反
Events::Recorder.call(action: :destroyed, task: task)

# ✅ GOOD: destroy 前に属性をキャプチャ、metadata に保存
task_snapshot = { task_id: task.id, task_name: task.name }
task.destroy!
Events::Recorder.call(action: :destroyed, metadata: task_snapshot)
```

属性のキャプチャは destroy 前に行うのが安全。

## 5. 日付フィルタの end_of_day

`<input type="date">` は `YYYY-MM-DD` を返すため、`Time.zone.parse` すると当日の `00:00:00` になる。`to` フィルタで `..time` とすると当日のイベントが除外される。

範囲末端には `.end_of_day` を付ける。詳細は `docs/conventions/USER_UI.md` 「`<input type="date">` の日付フィルタは end_of_day を付ける」を参照。
