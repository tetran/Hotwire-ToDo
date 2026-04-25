# Section Error

Section レベルの fetch 失敗を該当 section の本来位置に inline 表示する error コンポーネント。`Promise.allSettled` による partial render と組み合わせて、片側 API の失敗時にページ全体を error にせず該当 section のみを切り替える。

**Container**:
```
rounded-xl border border-rose-500/30 bg-rose-500/10 px-5 py-4
```

`ErrorBanner` (page-level、`rounded-lg`) と意図的に半径を分け、視覚的に section スコープであることを示す。

**Inner content**:
```
inline:  flex items-start gap-2  (icon + text を横並び)
stacked: flex flex-col gap-2     (narrow column 用、icon を text 上に積む)
```

**Icon**:
```
inline SVG (heroicons exclamation-triangle outline path)
h-4 w-4, strokeWidth=1.5, stroke="currentColor", text-rose-400
aria-hidden="true"
```

`docs/design/admin/foundations/icons.md` の sidebar nav と同 size / 同 stroke-width。lucide-react / heroicons パッケージは導入しない (Admin SPA は inline SVG 統一)。

**Text**:
```
title: font-semibold text-rose-400
body:  text-sm text-rose-400/80
```

`message` 未指定時のデフォルト文言: `「{title}を取得できませんでした。時間を置いて再度お試しください」`。

**Retry button** (optional, `onRetry` 指定時のみ表示):
```
type="button"
class: rounded-md border border-rose-400/30 px-3 py-1 text-xs font-medium text-rose-400
       transition hover:bg-rose-500/10
label: "再試行"
```

`Button` 共通抽象は導入せず、本コンポーネント内で inline `<button>` として実装する。

## Variants

| `layout` | 用途 | 例 |
|---|---|---|
| `inline` (default) | 通常幅の section / card 内 | `LlmProviderWorkspacePage` の Models 一覧、`UserRolePage` の roles fetch 失敗 |
| `stacked` | narrow column (System Status 等) | `DashboardPage` の System Status |

`layout` の auto 切り替え (CSS container query / ResizeObserver) は採用しない。判定が必要な利用箇所が増えた段階で再検討する。

## A11y

- root 要素に `role="alert"` + `aria-live="polite"`
- root 要素に test 用 `data-layout={layout}` を露出 (各ページ test で class string 非依存に variant をアサート可能)

## Props

```tsx
type SectionErrorProps = {
  title: string                    // 例: "モデル一覧"
  message?: string                 // 任意。デフォルトは title から自動生成
  onRetry?: () => void             // 任意。指定時のみ retry button 表示
  layout?: 'inline' | 'stacked'    // default: 'inline'
}
```

## 利用シーン

`Promise.allSettled` で並列 fetch する複数 section を持つページで、片側 fetch 失敗時に該当 section の本来位置に表示する。詳細パターンは `docs/conventions/ADMIN_UI.md` § 4.6 を参照。

ページ全体の操作フィードバック (form submit error など) は引き続き `ErrorBanner` を使用する。SectionError は **section 単位 fetch 失敗専用**。
