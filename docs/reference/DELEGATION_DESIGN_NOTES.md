# Delegation — 設計知見

`subagent-delegation` skill (`.claude/skills/subagent-delegation/`) で I2/I4 のサブエージェント運用ルールを定めた際、根拠として残しておきたい incident 観測値・段階的ロールアウト判断・pilot 振り返り規律をここに集約する。**通常の I2/I4 実行時にはこのドキュメントを参照する必要はない**。Dispatch caps の見直し、未知の subagent 強制停止の切り分け、過去の pilot 設計判断を辿りたい時にだけ開く。

ルール本体は `subagent-delegation` skill 側（正本スキーマ: `references/contract.md`、運用 playbook: `SKILL.md`）にあり、各ルール直下から本ドキュメントの該当章へリンクが張ってある。

---

## 1. Issue #332 force-stop incident — `maxTurns` 強制停止の挙動

`rails-developer` / `react-developer` の `maxTurns` ハードキャップ（現在 100、incident 当時 50）を超えた dispatch は agent を mid-work で強制停止する。Issue #332 はこのリポジトリ唯一の on-record インシデントで、19 page files の wholesale token-replacement + tests + self-review を 1 dispatch に詰め込んだ結果、当時の 50-turn cap に到達した。

このとき orchestrator から観測された挙動は次のとおり：

- **`SubagentStop` hook が発火しなかった**。`.claude/logs/subagent_responses.jsonl` には何も書き込まれず、フックベースのスキーマ検査が動かなかった。
- **`is_error` シグナルが orchestrator-visible なレイヤに上がってこなかった**。orchestrator が受け取ったのは in-flight `AssistantMessage` の途中（mid-sentence cutoff）テキストのみ。
- 結果として、レスポンス本文を直接見るまで「途中で停止した」ことが判別できなかった。

この観測から `subagent-delegation` skill の `references/contract.md` における Dispatch Sizing と Completion Verification は **response-content signals を前提に組まれている**（フック発火に依存しない）。`.claude/scripts/check-subagent-response.sh` を毎回手動で実行する規律はこの incident が直接の動機。

### Inferred, not officially confirmed

ここから先は仕様確認ではなく経験則：

- SDK wire format は `ToolResultBlock` に `is_error` フラグを許す。
- 公開ドキュメント上、closed-source CLI バイナリがこのフラグをいつセットするかの完全な条件は記述されていない。
- Issue #332 の挙動が **すべての** `maxTurns` 強制停止に一般化できるかは未検証。条件次第ではフックが発火する場合もあり得る。

`subagent-delegation` skill のルールは保守的にこの不確実性をカバーする立場 — 「フックが必ず発火する」と仮定せず、orchestrator が常に観測できるレスポンス本文に依拠する。新しい挙動を観測した場合はこの章を更新する。

## 2. Empirical bound — File caps の calibration ロジック

`subagent-delegation` skill `references/contract.md` の File caps（uniform 15 / non-uniform 10）は理論モデルから導出したものではなく、**Issue #332 で観測された 1 つの bound**（19-file wholesale token-replacement dispatch が 50-turn cap に到達）から逆算で calibrate した数値である。

closed-form turn model — 「N files の dispatch は M turns で終わる」と決定論的に予測する式 — は持っていない。理由は次のとおり：

- agent は 1 レスポンスに複数の tool call を batching できるため、turn 消費は agent の判断に依存する。
- 同じファイル数でも、独立 read-only なら 1 turn に収まり、Read-then-Edit のシリアル化が起きると turn 数が膨らむ。
- codex self-review は dispatch 内容にほぼ無関係に 5–10 turns を独占する。

このため caps は「19 files で爆発したのだから、その手前で安全マージンを切ろう」という観測ベースの決定で、**反証可能**である。あるクラスの dispatch（例: 同型の uniform edit）が安定して cap 内に収まることが観測されたら、そのクラス限定で caps を広げる材料になる。新しいデータを得た場合は PR description にその dispatch の構成（file 数 / 編集パターン / 消費 turn 数）を明記し、本章の根拠データを蓄積する。

## 3. Pilot phase rollout — Sequential → Parallel への段階的展開

DELEGATION 機構を導入した初期は次の段階で慣らした：

- **Start narrow**: Admin feature の追加（Rails API + React page）から開始。API 契約がクリーンで、Rails と React で工数が均しく分割でき、payoff が最大なケース。
- **Grow cautiously**: Sequential（Rails → React）パターンが安定したのを確認してから、独立タスク向けに parallel dispatch を解禁。

現在は sequential / parallel / fork-join の各パターンが定常運用に入っており、初期段階の「narrow に絞る」運用ガイダンスは役目を終えた。本ドキュメントは「なぜ今のルールセットがこの形なのか」を理解するための背景として残す。

新しい dispatch パターンを追加する際は、この段階的展開の作法をテンプレートにする：まず狭いユースケースで pilot し、観測値を得てからスコープを広げる。

## 4. Pilot 振り返りの規律 — observed paths と untouched paths の区別

Fork-join のような複合パターンを pilot した際、振り返りの書き方には特有の落とし穴があった。Happy path だけを動かして「契約は検証済み」と書いてしまうと、fallback branch（例: post-join type-mismatch redispatch）が pilot で trigger されていないという事実が抜け落ちる。

そこで pilot retrospection の規律として次を採用した：

- **観測したパス**（実際に走り、artifact を生んだ経路）と
- **未観測のパス**（happy path が触らなかった、negative evidence しかない経路）

を明示的に分けて書く。fallback branch が pilot 範囲外だった場合は **untested** と明記し、その経路に関する一般化主張は避ける。

この規律自体は pilot 期間が終わった現在も「観測してない経路は untested と書く」という一般則として `subagent-delegation` skill `references/contract.md` の Fallback Triggers 末尾に圧縮して残してある。pilot 期固有の言い回しと fork-join への適用例を、この章に保存する。

---

## Cross-references

- 運用ルール本体: `.claude/skills/subagent-delegation/` (`references/contract.md` + `SKILL.md`)
- スキーマ検査スクリプト: `.claude/scripts/check-subagent-response.sh`
- フック実装: `.claude/hooks/subagent_stop_format_check.sh`
- Agent loop の turn 定義: [Claude Agent SDK — Agent loop](https://code.claude.com/docs/en/agent-sdk/agent-loop)
- Issue #332 PR: `f8d8d13` (PR #347 — fix/issue-332-delegation-batching)
