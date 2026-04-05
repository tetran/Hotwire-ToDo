# Active Record クエリ規約

存在チェックと件数取得における `present?` / `exists?` / `any?` / `count` / `length` / `size` の使い分けルール。無駄なクエリを発行せず、必要な場面では追加クエリを発生させないことが目的。

## TL;DR（AIエージェント向け判断基準）

**レコードをその後使うかどうかで決める。**

- レコードを**使わない**（存在や件数を知りたいだけ） → DBに計算させる（`exists?` / `count`）
- レコードを**使う**（ループや表示に利用する） → ロード結果を流用する（`present?` / `length` / `size`）
- **迷ったら** → `size`（Relation がロード済みかどうかを判別して最適化する）

## シチュエーション別・使うべきメソッド

| シチュエーション | 使うメソッド | 発行SQL | 備考 |
|---|---|---|---|
| 存在チェックのみ（レコード未使用） | `exists?` | `SELECT 1 ... LIMIT 1` | 最軽量 |
| 存在チェック後にそのままレコードを使う | `present?` | `SELECT xxx.*` | ロード結果を再利用 |
| 件数のみ欲しい（レコード未使用） | `count` | `SELECT COUNT(*)` | 毎回COUNTを発行する |
| 件数を取得後にそのままレコードを使う | `length` または `size` | `SELECT xxx.*` | 配列長を返す |
| ロード状態が不明／迷った | `size` | 状況により最適化 | 未ロード→COUNT、ロード済→配列長 |
| `counter_cache` 有りの関連の件数 | `size` | クエリ0発 | キャッシュカラムを参照 |
| 2件以上あるかだけ確認 | `many?` | `SELECT COUNT(*) LIMIT 2` | 全件数えずに判定可能 |

## 各メソッドの挙動（詳細）

### 存在チェック系

| メソッド | 挙動 |
|---|---|
| `exists?` | 常に `SELECT 1 ... LIMIT 1` を発行。Relation は**ロードしない** |
| `any?`（ブロック無し） | 内部で `!empty?` を呼ぶ。未ロード時は `exists?` 相当（`SELECT 1 ... LIMIT 1`） |
| `present?` | `!blank?`。Relation の `blank?` は `records.blank?` として定義されており**全件ロード**する |
| `blank?` | Relation を**全件ロード**する（`present?` と同じ） |
| `empty?` | 未ロード時は内部で `!exists?`、ロード済み時は配列の `empty?` |

### サイズ取得系

| メソッド | 未ロード時 | ロード済み時 |
|---|---|---|
| `count` | `SELECT COUNT(*)` を発行 | **ロード済みでも毎回COUNTを発行**（キャッシュ無視） |
| `length` | **全件ロード**してから `Array#length` | 配列長を返す（追加クエリ無し） |
| `size` | `count` と同じ（COUNTクエリ） | `length` と同じ（追加クエリ無し） |

## ルール

### Rule 1: 存在チェックの後にレコードを使う場合は `present?`

```ruby
# ❌ NG: exists? とループで2回クエリが発行される
if users.exists?
  users.each { |u| send_email(u) }
end

# ✅ OK: present? なら1回のロードで済む
if users.present?
  users.each { |u| send_email(u) }
end
```

### Rule 2: レコードを使わない存在チェックは `exists?`

```ruby
# ❌ NG: present? は全件ロードする
if User.where(active: true).present?
  redirect_to dashboard_path
end

# ✅ OK: exists? は SELECT 1 ... LIMIT 1
if User.where(active: true).exists?
  redirect_to dashboard_path
end
```

### Rule 3: 件数のみ欲しい場合は `count`、後で使うなら `size`

```ruby
# ❌ NG: length は全件ロードしてしまう
total = User.where(active: true).length

# ✅ OK: 件数だけなら count
total = User.where(active: true).count

# ✅ OK: 後で使うなら size（未ロードならCOUNT、ロード済みなら配列長）
users = User.where(active: true).to_a
total = users.size  # 追加クエリ無し
```

### Rule 4: `counter_cache` がある関連の件数は `size` を使う

```ruby
class Post < ApplicationRecord
  has_many :comments, counter_cache: true
end

# ❌ NG: count は毎回 COUNT クエリを発行し、キャッシュを無視する
post.comments.count

# ✅ OK: size は counter_cache カラムを読むだけで追加クエリ無し
post.comments.size
```

### Rule 5: ループ内で件数を取る場合は `counter_cache` + `size` にする

```ruby
# ❌ NG: N+1 の COUNT クエリが発生する
@posts.each do |post|
  "#{post.comments.count} comments"
end

# ✅ OK: counter_cache を設定した上で size を使う
@posts.each do |post|
  "#{post.comments.size} comments"
end
```

## 意思決定フローチャート

```
その後レコードを使うか？
├─ YES → 存在チェック: present? / 件数取得: length または size
│        （ロードが無駄にならない）
│
└─ NO  → 何を知りたいか？
         ├─ 存在するか         → exists?
         ├─ 件数が欲しい       → count
         └─ 2件以上あるか     → many?
```

## アンチパターン集

| アンチパターン | 問題点 | 代替 |
|---|---|---|
| `relation.exists?` した後に `relation.each` | クエリ2回発行 | `present?` で判定しつつロード |
| `relation.present?` で存在チェックだけ | 全件ロードが無駄 | `exists?` |
| `relation.length` で件数だけ取得 | 全件ロードが無駄 | `count` |
| `post.comments.count`（counter_cache 有り） | キャッシュ無視で毎回COUNT | `size` |
| ループ内での `association.count` | N+1 COUNT クエリ | `counter_cache` + `size` |

## 参考

- Rails Guides: [Active Record Query Interface - Existence of Objects](https://guides.rubyonrails.org/active_record_querying.html#existence-of-objects)
- `ActiveRecord::Relation#blank?` は `records.blank?` として定義されており、Relation をロードする
- `ActiveRecord::Relation#size` は `loaded?` によって `count` / `length` を切り替える

