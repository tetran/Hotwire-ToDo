# Models

モデルが肥大化した場合の分解パターンは [docs/conventions/FAT_MODEL_DECOMPOSITION.md](../../docs/conventions/FAT_MODEL_DECOMPOSITION.md) を参照。

## 現在適用済みのパターン

| パターン | クラス | 元モデル |
|----------|--------|----------|
| Value Object | `RecurrenceRule` | TaskSeries のスケジューリングロジック |
| Policy Object | `AdminPolicy` | User の認可メソッド |
| Concern | `Task::Broadcasting` | Task の broadcast コールバック |
