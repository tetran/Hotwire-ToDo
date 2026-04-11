# Admin UI Convention

React SPA（Vite + TailwindCSS v4）での Admin 画面開発規約。
デザインシステムの詳細は `docs/design/admin/README.md` を参照（トピック別に分割）。

---

## 1. テクノロジースタック

| 層 | 技術 |
|---|---|
| フレームワーク | React |
| ビルド | Vite |
| スタイリング | TailwindCSS v4 |
| フォント | Syne（見出し）、DM Mono（ラベル）、システムフォント（本文） |
| ルーティング | React Router |

**禁止**: Hotwire / Turbo は使わない。Admin は React + JSON API のみ。

---

## 2. カラー

### トークン優先

新規コンポーネントでは CSS 変数トークンを使う。ハードコード値は使わない。

```tsx
// ✅ Good
className="bg-sidebar"        // → #0f1117
className="bg-accent"         // → #6366f1
className="bg-surface"        // → #f8f9fc

// ❌ Bad
className="bg-[#0f1117]"      // ハードコード
```

トークンは `app/javascript/admin/styles/admin.css` の `@theme` で定義済み：

| トークン | Tailwind クラス | 用途 |
|---|---|---|
| `--font-syne` | `font-syne` | 見出し、統計値 |
| `--font-dm-mono` | `font-dm-mono` | カテゴリラベル、ID |
| `--color-sidebar` | `bg-sidebar` | サイドバー背景 |
| `--color-sidebar-border` | `border-sidebar-border` | サイドバー境界線 |
| `--color-accent` | `bg-accent` | プライマリアクセント |
| `--color-surface` | `bg-surface` | メインコンテンツ背景 |

### テキスト階層

| 用途 | クラス |
|---|---|
| 見出し・統計値 | `text-slate-800` |
| 本文・名前 | `text-slate-700` |
| ナビセクションラベル | `text-slate-600` |
| キャプション・メタデータ | `text-slate-400` |
| タイムスタンプ | `text-slate-500` |
| ダーク上のテキスト | `text-white` |
| ダーク上の控えめテキスト | `text-slate-200` |

### セマンティックカラー（Badge 用）

3層構造: 背景(15% opacity) + テキスト(400 shade) + ring(30% opacity)

| バリアント | 背景 | テキスト | Ring |
|---|---|---|---|
| success | `bg-emerald-500/15` | `text-emerald-400` | `ring-emerald-500/30` |
| danger | `bg-rose-500/15` | `text-rose-400` | `ring-rose-500/30` |
| info | `bg-indigo-500/15` | `text-indigo-400` | `ring-indigo-500/30` |
| neutral | `bg-slate-500/15` | `text-slate-400` | `ring-slate-500/30` |
| warning | `bg-amber-500/15` | `text-amber-400` | `ring-amber-500/30` |

---

## 3. タイポグラフィ

### フォントの使い分け

| フォント | 用途 | 適用方法 |
|---|---|---|
| Syne | ページタイトル、カード見出し、統計値、ロゴ | `style={{ fontFamily: 'Syne, sans-serif' }}` |
| DM Mono | スーパーラベル、セクションラベル、ID列 | `style={{ fontFamily: 'DM Mono, monospace' }}` |
| システムフォント | その他すべて | デフォルト |

### テキストサイズ

| 役割 | サイズ | ウェイト | フォント |
|---|---|---|---|
| ページタイトル | `text-2xl` | `font-bold` | Syne |
| カード見出し | `text-lg` | `font-semibold` | Syne |
| 統計値 | `text-3xl` | `font-bold` | Syne |
| 本文 | `text-sm` | `font-medium` | Default |
| テーブルヘッダー | `text-xs` | `font-semibold` + `uppercase tracking-wider` | Default |
| スーパーラベル | `text-[10px]` | `font-semibold` + `tracking-[0.2em]` | DM Mono |
| セクションラベル | `text-[9px]` | `font-semibold` + `tracking-[0.15em]` | DM Mono |

---

## 4. コンポーネントパターン

### ページヘッダー

すべてのページで統一した構造を使う：

```tsx
<div className="flex items-end justify-between">
  <div>
    <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
       style={{ fontFamily: 'DM Mono, monospace' }}>
      SECTION_NAME
    </p>
    <h1 className="text-2xl font-bold text-slate-800"
        style={{ fontFamily: 'Syne, sans-serif' }}>
      Page Title
    </h1>
    <p className="mt-0.5 text-xs text-slate-400">Subtitle text</p>
  </div>
  {/* 右側: アクションボタン / 検索 */}
</div>
```

### カードコンテナ

```tsx
// 標準カード
<div className="rounded-xl border border-slate-200 bg-white shadow-sm">

// カードヘッダー付き
<div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
  <h3 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>
    Title
  </h3>
</div>
```

### ボタン

| バリアント | クラス |
|---|---|
| Primary | `rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]` |
| Secondary | `rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50` |
| Danger | `rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50` |
| Text Link | `text-xs text-[#6366f1] hover:underline` |

### テーブル

```tsx
// コンテナ
<div className="rounded-xl border border-slate-200 bg-white shadow-sm">

// ヘッダー行
<tr className="border-b border-slate-100">
  <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">

// ボディ行
<tbody className="divide-y divide-slate-50">
  <tr className="transition-colors hover:bg-slate-50/50">
    <td className="px-5 py-3.5">
```

### Badge

```tsx
<span className="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium
  bg-{color}-500/15 text-{color}-400 ring-1 ring-{color}-500/30">
```

---

## 5. レイアウト

### 全体構造

- サイドバー: `w-[220px]` 固定、`bg-[#0f1117]`
- メインコンテンツ: `flex-1`、`p-6`、`bg-[#f8f9fc]`
- トップヘッダー: `h-14`、`bg-white`、`border-b border-slate-200`

### グリッド

| 用途 | クラス |
|---|---|
| 統計カード | `grid grid-cols-2 gap-4 lg:grid-cols-4` |
| ダッシュボード下部 | `grid grid-cols-1 gap-4 lg:grid-cols-3` |
| セクション間隔 | `space-y-5` or `space-y-6` |

---

## 6. シャドウ

| レベル | クラス | 用途 |
|---|---|---|
| Subtle | `shadow-sm` | カード、パネル、テーブル |
| Medium | `shadow-md shadow-indigo-500/20` | プライマリボタン |
| Accent | `shadow-md shadow-indigo-500/30` | ロゴアイコン |

**ルール**: アクセントカラー要素のみ `shadow-indigo-500/XX` を使用。他は `shadow-sm`。

---

## 7. ボーダーとラディウス

### ボーダー

| 用途 | クラス |
|---|---|
| カード外枠 | `border border-slate-200` |
| パネル区切り | `border-b border-slate-100` |
| 行区切り | `divide-y divide-slate-50` |
| サイドバー | `border-r border-[#1e2130]` |

### ラディウス

| サイズ | クラス | 用途 |
|---|---|---|
| full | `rounded-full` | Badge, Avatar |
| xl | `rounded-xl` | カード、パネル、テーブル |
| lg | `rounded-lg` | ボタン、ナビアイテム、入力 |
| md | `rounded-md` | 小ボタン（edit/delete） |

---

## 8. アイコン

- スタイル: インライン SVG、アウトライン（`fill="none"` + `stroke="currentColor"`）
- サイドバーナビ: `h-4 w-4`、`strokeWidth={1.5}`
- 統計カード: `h-5 w-5`、`strokeWidth={1.5}`
- 小UIアイコン: `h-3.5 w-3.5`、`strokeWidth={2}`

---

## 9. 新コンポーネント チェックリスト

新しいコンポーネントを作る際に確認：

1. [ ] カードコンテナに `rounded-xl border border-slate-200 bg-white shadow-sm` を使用
2. [ ] カード内の見出しに `Syne` フォントを使用
3. [ ] カテゴリラベルに `DM Mono` + 適切な tracking を使用
4. [ ] プライマリアクションに `#6366f1` + `shadow-md shadow-indigo-500/20` を使用
5. [ ] テーブルヘッダーに `text-xs font-semibold uppercase tracking-wider text-slate-400`
6. [ ] ステータス表示に Badge コンポーネントの正しいバリアントを使用
7. [ ] ホバーに `transition` or `transition-colors` を含める
8. [ ] テキスト階層が slate スケールに従う: 800 > 700 > 600 > 400 > 500

