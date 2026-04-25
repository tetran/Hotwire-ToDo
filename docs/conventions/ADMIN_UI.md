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

### 4.5 戻るナビゲーション

admin画面の「前画面に戻る」UIは意味論で2種に分離。

| ページ種別 | 使うコンポーネント | 配置 | 例 |
|---|---|---|---|
| Detail / 閲覧 | `<AdminBackLink>` | ページヘッダー左上（`space-y-6` の先頭子要素） | AdminAccountDetail |
| ネスト Index（親が Detail） | `<AdminBackLink>` | ページヘッダー左上（同上）、label は親リソース単数形 | LlmModels（親: LlmProvider Detail） |
| Edit / New / 設定フォーム | `<AdminCancelButton>` | フォームフッター、Saveボタンの左隣 | UserEdit, RolePermission |
| Top-level Index / Dashboard 等 | （無し） | — | 親が存在しないページ |

**AdminBackLink**：`<Link>` ベース。props: `to`（親ルート）, `label`（親リソース名）。例：`<AdminBackLink to="/admin/users" label="Users" />`。ネスト Index の場合は親 Detail を指し、label は親リソース単数形（例：`<AdminBackLink to="/admin/llm-providers/:id" label="Provider" />`）。アクセシビリティのため `aria-label="Back to {label}"` を内部で自動付与。

**AdminCancelButton**：`<button type="button">` + `useNavigate` ベース。props: `to`。固定ラベル "Cancel"。`<Link>` を使わないのは、Cmd/Ctrl-click で別タブに「親リストを開く」挙動が Cancel の意味論（編集破棄して同コンテキスト離脱）と矛盾するため。

#### Semantic Invariants

| 項目 | AdminBackLink | AdminCancelButton |
|---|---|---|
| HTML | `<a>` (react-router `<Link>`) | `<button type="button">` |
| role | `link` | `button` |
| Cmd/Ctrl-click | 新タブで開く（意図通り） | 無効（意図通り） |
| keyboard | Tab + Enter | Tab + Enter/Space |
| form submit risk | N/A | `type="button"` で防止 |

**Do**：
- Detail ページはヘッダー領域の上に `AdminBackLink` を1つだけ配置
- Edit/New フォームは `AdminCancelButton` をフォームフッターでプライマリアクションの左隣に配置

**Don't**：
- Cancel を `<Link>` に置き換えない
- Back と Cancel を同じページで併用しない
- Index / Dashboard / Login 等に戻るUIを追加しない

### 4.6 Section error UI / Partial-failure handling

複数 API を並列 fetch するページで片側が失敗してもページ全体を error にせず、**section 単位で個別 partial render** する規約。詳細仕様は `docs/design/admin/components/section-error.md` を参照。

**Do**：
- 並列 fetch は `Promise.allSettled` を使う。`Promise.all` は使わない (片側失敗で全体 reject、partial render が効かなくなる)
- section ごとに独立した error state (例: `permissionsError` / `assignedError`) を持ち、SectionError はその section の本来位置に inline 表示する
- 両側失敗時もページ全体を error にせず、各 section が個別に SectionError を出す
- `SectionError` の `layout` prop は narrow column (System Status 等) でのみ `"stacked"` を渡し、それ以外は default `"inline"` を使う

**Don't**：
- 並列 fetch に `Promise.all` + 単一 catch を使わない (partial render が成立しない)
- ページ最上部に集約 error UI として SectionError を置かない (本来位置に inline 表示が原則)
- fetch error と form submit error を同じ単一 error state で兼用しない (fetch は SectionError、submit は `ErrorBanner` で分離)

```tsx
// ✅ Good: 並列 fetch を allSettled で section 単位 error 化
const [resA, resB] = await Promise.allSettled([apiA(), apiB()])
if (resA.status === 'fulfilled') setA(resA.value)
else setAError(buildSectionErrorMessage(resA.reason))
if (resB.status === 'fulfilled') setB(resB.value)
else setBError(buildSectionErrorMessage(resB.reason))

// JSX
{aError ? <SectionError title="A 一覧" onRetry={refresh} /> : <AView data={a} />}
{bError ? <SectionError title="B 一覧" onRetry={refresh} /> : <BView data={b} />}
```

```tsx
// ❌ Bad: 片側失敗でページ全体が error になる
Promise.all([apiA(), apiB()])
  .then(([a, b]) => { setA(a); setB(b) })
  .catch(err => setError(err.message))   // ← 片方失敗で全体 error
```

#### form を持つページの方針

form の入力選択肢を構成する fetch (例: `permissionsApi.list` の全 permissions) が失敗した場合、submit は引き続き可能にしたうえで依存 fetch 失敗を SectionError で明示する。submit 結果の整合性は server 側 validation に委ねる方針 (UI 側で form を hard-disable はしない)。理由: partial UI で操作継続性を保つのが本規約の主旨であり、楽観的 UI を維持。

submit 由来 error は引き続き `ErrorBanner` を form 直前 (page header 直下) に配置して表示する。`submitError` は fetch 由来の section error state とは別 state として保持する。

##### 例外: 現在状態 fetch (assignedRoles 等) 失敗時は Save を disable

form の入力選択肢 (例: 全 roles 一覧) と **現在の割り当て状態** (例: 該当 user の assignedRoles) を別々に並列 fetch する画面では、**現在状態側の fetch が失敗した場合は Save button を disable する** こと。これは本規約の主原則「submit 引き続き可能」の例外で、理由は以下:

- 現在状態 fetch 失敗時、form state (`selectedRoleIds` 等) は初期値の空配列のまま
- そのまま Save を許すと空配列で submit され、backend が「全削除」と解釈し silent data-loss を引き起こす
- 楽観的 UI の利点 (操作継続性) より、user の意図しない data 破壊を防ぐ side が優先

実装パターン:
```tsx
<button type="submit" disabled={!!assignedError}
  className="... disabled:opacity-50 disabled:cursor-not-allowed">
  Save
</button>

<SectionError
  title="割り当て済みロール"
  message="現在の割り当てを取得できなかったため Save できません。再試行してください。"
  onRetry={() => setRefreshKey(k => k + 1)}
/>
```

options list 側 (`rolesApi.list` 等) の fetch 失敗は引き続き Save **enabled** のまま (主原則どおり)。disable 判定は **現在状態 fetch error のみ** を OR 条件に入れる。

**両方失敗時の SectionError 表示優先順位**: options list と現在状態の **両方** が失敗した場合、JSX の ternary 順序で **現在状態 (`assignedError` 等) 側 SectionError を先に評価** すること。理由は、Save が disable される根本理由 (現在状態が不明) を user に伝える explanatory message を確実に表示するため。options list 側 SectionError は片方のみ失敗時のみ render されればよい。

#### Structural fetch の例外

ページ chrome (`<h1>` のページタイトルを構成する provider 名 等) を成立させる fetch は **structural fetch** と呼ぶ。structural fetch の失敗時は section 単位 partial render の対象外で、**従来の full-page error fallback** を採用する。理由は、render する page identity 自体が失われるため。

例: `LlmProviderWorkspacePage` の provider fetch は structural fetch (`<h1>LLM Provider: {provider.name}</h1>` を構成)。provider fetch 失敗時は full-page error、provider 成功 + models 失敗時のみ Models 位置に SectionError を出す。

#### Out of Scope

- mutation API (POST / PATCH / DELETE) の error handling は本規約の対象外
- 多段階 (chained) fetch (例: `providers.list()` → 各 provider について `models.list()` を回す) の partial-failure 戦略は本規約の対象外、別 issue で扱う
- 自動 retry 機構は本規約に含まない (`onRetry` は user 起動の手動 retry のみ)

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

