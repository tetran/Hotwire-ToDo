# User UI Convention

Rails + Hotwire（Turbo Streams / Frames / Stimulus）でのユーザー画面開発規約。
デザインシステムの詳細は `docs/design/user/README.md` を参照（トピック別に分割）。

---

## 1. テクノロジースタック

| 層 | 技術 |
|---|---|
| フレームワーク | Rails（サーバーレンダリング） |
| インタラクション | Hotwire（Turbo Streams, Turbo Frames, Stimulus） |
| スタイリング | Plain CSS + Water.css v2 (light) |
| アイコン | Material Symbols Outlined（Google Fonts CDN） |
| フォント | システムフォントのみ |

### 現状の技術選択

- CSS フレームワーク（Tailwind, Bootstrap）は現時点では未導入。Plain CSS + Water.css で構築している。
- カスタム Web フォントは未導入。システムフォントのみ使用。
- Admin SPA のパターン（Syne/DM Mono, ダーク, indigo アクセント）は User 側とは別のデザイン言語であり、流用しない。
- ダークモードは現時点では未実装。ライトテーマのみで運用している。

---

## 2. カラー

### CSS 変数を使う（ハードコード禁止）

```css
/* ✅ Good */
color: var(--color-accent);
background: var(--color-error-bg);

/* ❌ Bad */
color: #0096bf;
background: #f2dede;
```

### ブランドカラー

| 変数 | 値 | 用途 |
|---|---|---|
| `--color-accent` / `--button-primary` | `#0096bf` | プライマリボタン背景 |
| `--color-accent-hover` / `--button-primary-hover` | `#007a9d` | プライマリボタンホバー |
| `--color-accent-contrast` / `--button-primary-text` | `#eee` | プライマリボタンテキスト |

**ルール**: アクセントカラーはプライマリアクションボタン専用。装飾目的では使わない。

### セマンティックカラー

| 変数 | 値 | 用途 |
|---|---|---|
| `--color-error` | `#fc5050` | エラー、期限切れ、破壊的操作 |
| `--color-warning` | `#8a6d3b` | 警告テキスト |
| `--color-success` | `#3c763d` | 成功テキスト |
| `--color-info` | `#31708f` | 情報テキスト |

背景付きバリアント: `--color-error-bg`, `--color-warning-bg`, `--color-success-bg`, `--color-info-bg`

**ルール**: `--color-error` はエラーと破壊的操作のみ。ハイライト用途には使わない。

### テキスト階層

| レベル | 値 | 用途 |
|---|---|---|
| Primary | `var(--text-main)` | タスク名、本文 |
| Form/Link | `var(--form-text)` | インタラクティブテキスト |
| Muted | `var(--color-muted)` | 説明、日付、タイムスタンプ |
| Error | `var(--color-error)` | 期限切れ、エラー |

---

## 3. タイポグラフィ

### サイズスケール

| 変数 | 値 | 用途 |
|---|---|---|
| `--text-xs` | `0.75rem` (12px) | 二次メタ情報 |
| `--text-sm` | `0.875rem` (14px) | タスクメタ、説明、検索結果 |
| `--text-base` | `1rem` (16px) | 本文、フォーム入力、タスク名 |
| `--text-lg` | `1.125rem` (18px) | モーダルタイトル、セクション見出し |

### ウェイト

- `400`: デフォルト
- `500`: 検索結果名
- `700`: コメントユーザー名、モーダルタイトル、現在のプロジェクト

追加のウェイトは導入しない。

---

## 4. スペーシング

### トークンベースのスペーシング

```css
/* ✅ Good */
padding: var(--space-2) var(--space-3);
gap: var(--space-1);

/* ❌ Bad */
padding: 8px 12px;
gap: 4px;
```

| 変数 | 値 | 用途 |
|---|---|---|
| `--space-1` | `0.25rem` (4px) | アイコンギャップ、バッジパディング |
| `--space-2` | `0.5rem` (8px) | 要素間ギャップ、メニューアイテム |
| `--space-3` | `0.75rem` (12px) | カード内スペース、モーダルパディング |
| `--space-4` | `1rem` (16px) | フォームアイテムマージン |
| `--space-5` | `1.5rem` (24px) | セクション間隔 |
| `--space-6` | `2rem` (32px) | 大セクション分離 |

---

## 5. CSS クラス命名

### BEM 記法

```css
/* ✅ Good: BEM */
.task-card { }
.task-card__content { }
.task-card__name { }
.task-card--complete { }

/* ❌ Bad */
.taskCard { }           /* camelCase */
.task-card .content { }  /* 子孫セレクタの乱用 */
```

---

## 6. コンポーネントパターン

### ボタン

| バリアント | クラス | 見た目 |
|---|---|---|
| Primary | `.btn.primary` or `button.primary` | シアン `#0096bf`、ライトテキスト |
| Secondary | `.btn`（修飾子なし） | Water.css デフォルトサーフェス |
| Danger | `.btn.danger` | エラーカラーのテキスト/ボーダー |
| Icon | `.btn.btn--icon` | 透明背景、ホバーで薄い背景 |

### モーダル / ダイアログ

- ネイティブ `<dialog>` 要素を使う（`.modal-base`）
- `showModal()` で開く
- `::backdrop` は `var(--overlay-scrim)`
- 幅: `min(80vw, 600px)`
- ボディ最大高: `75vh`
- border-radius: `var(--radius-lg)` (8px)

### 通知 / トースト

- `.notification` + `.notification__contents--{status}`
- 最大幅: `var(--toast-max-width)` (400px)
- アニメーション: `fadeInOut 1.5s`

### アイコン + テキストの配置

```css
/* ✅ Good: inline-flex パターン */
.label-with-icon {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
}

/* ❌ Bad: vertical-align ハック */
.icon { vertical-align: -4px; }
```

### Toggle Chip（選択チップ）

```css
.chip {
  display: inline-flex;
  align-items: center;
  padding: var(--space-1) var(--space-2);
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  font-size: var(--text-xs);
}
.chip:has(input:checked) {
  background: color-mix(in srgb, var(--color-accent) 12%, transparent);
  color: var(--color-accent);
  border-color: var(--color-accent);
}
```

---

## 7. レイアウト

### 全体構造

- 水平ヘッダー（サイドバーなし）
- Water.css のセンタリングされたコンテナ
- プロジェクトセレクター（左）、検索・メンバー・ユーザーメニュー（右）

**ルール**: サイドバーを追加しない。水平ヘッダーレイアウトを変更しない。

### モーダルオーバーレイ

- ネイティブ `<dialog>` + `showModal()`
- Turbo Frame `modal` にサーバーサイドレンダリング
- フルページリロードを想定しない

---

## 8. ボーダーとラディウス

### ボーダー

| 用途 | 値 |
|---|---|
| カード、フォーム、区切り | `1px solid var(--border)` |
| チェックボックス | `1px solid var(--selection)` |
| ボタン、アイコンボタン | ボーダーなし |

### ラディウス

| 変数 | 値 | 用途 |
|---|---|---|
| `--radius-sm` | `4px` | ドロップダウン、メニューアイテム |
| `--radius-md` | `6px` | ボタン、アクションアイコン |
| `--radius-lg` | `8px` | モーダル、タスクフォーム |
| `--radius-pill` | `1rem` | コメント入力、チップ |
| `--radius-full` | `50%` | アバター、チェックボックス |

---

## 9. シャドウ

| 変数 | 値 | 用途 |
|---|---|---|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.08)` | カード（将来） |
| `--shadow-md` | `0 0 10px rgba(0,0,0,0.3)` | ドロップダウン、トースト |
| `--shadow-lg` | `0 4px 20px rgba(0,0,0,0.15)` | モーダル |

**ルール**: アクセント付きシャドウ（`shadow-indigo-500/20` 等）は使わない。ニュートラルグレーのみ。

---

## 10. アイコン

Material Symbols Outlined のみ使用。

### サイズ使い分け

| サイズ | 用途 |
|---|---|
| `1rem` | タスクメタ（期日、サブタスク） |
| `1.2rem` | ラベル付きアイコン |
| `1.5rem` | メニューボタントリガー |

### カラー

- アイコンは親の `color` を継承
- 破壊的操作のみ `var(--color-error)` を使用

---

## 11. アクセシビリティ

### 必須ルール

1. **フォーカスリングを消さない**: `outline: none` や `box-shadow: none` をインタラクティブ要素に適用しない
2. **ホバーで表示されるアクションは focus-within でも表示**: キーボードユーザーがアクセスできるようにする
3. **非選択状態に `opacity` を使わない**: `:disabled` と視覚的に衝突する。代わりに `var(--color-muted)` を使う
4. **チップの `:focus-within` アウトラインは必須**: 隠しチェックボックスのフォーカス追跡のため

---

## 12. Turbo / Stimulus 連携

### CSS の前提

- コンポーネントはいつでも Turbo Stream で差し替えられる
- DOM ノードより長生きする JS 状態を持たない
- Stimulus コントローラーは DOM ライフサイクルに従う

### フォーカスリング

Water.css のデフォルト `box-shadow: 0 0 0 2px var(--focus)` を全入力で統一。

### インライン編集は Turbo Frame をフィールド単位で分ける

ページに既に Turbo Frame（モーダル等）がある状態でインライン編集を追加する場合、編集対象フィールドごとに独自IDの `turbo_frame_tag` で包む。各フィールドが独立して display ↔ edit をトグルできる。

- Frame ID 例: `"task_#{id}_#{field}"`（例: `task_42_name`, `task_42_due_on`）
- Display partial: frame を edit アクションに遷移させる `link_to`
- Edit template: 同じ frame タグ内の PATCH フォーム
- Cancel: 同じ frame を show に戻す link
- Turbo Stream レスポンス: frame を display partial に差し替え

**Frame ID 衝突に注意**: タスクカードは `turbo_frame_tag @task` (`dom_id`)、モーダルは `turbo_frame_tag "modal"` を使っているので、インラインフィールドは必ずカスタム ID にする。

**バリデーション失敗時の format.turbo_stream 落とし穴**: `format.turbo_stream` ブロック内で HTML テンプレート（例: `edit.html.erb`）を render する場合、`formats: [:html]` を明示しないと Rails が `edit.turbo_stream.erb` を探してエラーになる。

```ruby
format.turbo_stream { render :edit, formats: [:html], status: :unprocessable_content }
```

### ActionText を link_to で包まない

ActionText の rich text（例: `task.description`）を `link_to` ブロックの中でレンダリングすると、rich text 自身にリンクや attachment が含まれる場合にネストした `<a>` タグが出力されてしまい、無効な HTML になる。

リッチテキストをクリッカブルにしたい場合は、`<div>` ラッパー + 別途 edit アイコンオーバーレイのパターンを使う。`link_to` はプレーンテキストフィールド（タスク名、期日など）だけに使う。

```erb
<%# ❌ BAD: description にリンクが含まれるとネスト <a> になる %>
<%= link_to edit_path do %>
  <%= task.description %>
<% end %>

<%# ✅ GOOD: div ラッパー + 別アイコン %>
<div class="editable">
  <%= task.description %>
  <%= link_to edit_path, class: "edit-overlay" do %>
    <span class="material-symbols-outlined">edit</span>
  <% end %>
</div>
```

### `<input type="date">` の日付フィルタは end_of_day を付ける

`<input type="date">` は `YYYY-MM-DD` を返す。`Time.zone.parse` すると当日の `00:00:00` になるため、`to` フィルタで `..time` とすると当日のイベントが範囲外になる。範囲の末端には必ず `.end_of_day` を付ける:

```ruby
# ❌ BAD: 当日のイベントが除外される
scope.where(created_at: ..Time.zone.parse(params[:to]))

# ✅ GOOD
scope.where(created_at: ..Time.zone.parse(params[:to]).end_of_day)
```

---

## 13. i18n ラベル

### 類義語衝突チェック

日本語ラベルを追加する時は、既存ラベルと類義・同義にならないかチェックする。特に**同じフォームに並ぶ可能性があるラベル**は要注意。

**例**: 「期日」と「期限日」はほぼ同義 → 「終了日」と「締切日」のように意味を分離した。

---

## 14. 新コンポーネント チェックリスト

1. [ ] Water.css の要素スタイルを最大限活用し、カスタム CSS は構造レイアウトとブランド差別化のみ
2. [ ] BEM 命名: `block__element--modifier`
3. [ ] トークン参照、hex リテラル禁止: `var(--color-accent)` not `#0096bf`
4. [ ] スペーシングトークン使用: `var(--space-3)` not `0.75rem`
5. [ ] Material Symbols Outlined + inline-flex + `gap: var(--space-1)` でアイコン配置
6. [ ] キーボードナビゲーション可能: フォーカスアウトラインを消さない
7. [ ] オーバーレイはネイティブ `<dialog>`（`.modal-base` 再利用）
8. [ ] Turbo Stream 対応: いつでも DOM 差し替え可能な設計
9. [ ] `--color-error` はエラーと破壊的操作のみ

