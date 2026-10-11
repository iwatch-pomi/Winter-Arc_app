# Winter Arc

> Better me. Stronger future.
> 冬の努力が、最高の自分をつくる。

「冬の挑戦期間（Winter Arc）」を管理する iPhone 向け自己成長アプリです。
SwiftUI + SwiftData で作られていて、外部ライブラリやサーバーは使いません（データは端末内に保存）。

## 機能

| タブ / 画面 | できること |
| --- | --- |
| ホーム | 日付・今日のひとこと・シーズン進捗（Day X / 90）、今週の進捗（タスク完了 / 習慣達成日 / 勉強時間）、次のタスク、目標 |
| タスク | 週カレンダー、カテゴリ絞り込み（勉強・筋トレ・生活・その他）、15分単位の時刻設定、完了チェック、スワイプで削除、前日のタスクをコピー |
| 習慣 | 今週の達成率、習慣ごとに月〜日の丸をタップして達成記録、連続日数、月カレンダー、アイコン選択 |
| 記録 | 週間 / 月間 / 年間の切り替え。勉強時間・体重・タスク完了数・運動時間・読書冊数・睡眠時間をグラフ表示 |
| 設定 | ニックネーム、目標体重、シーズン期間、目標管理、毎日のリマインダー通知、集中モードの時間、データ削除 |
| 目標設定（初回） | 目標入力 → 期間設定 → 習慣選択 |
| 集中モード | ポモドーロタイマー。終わると勉強時間に自動記録 |
| 今日の名言 | 日替わりの名言と「今日のハイライト」 |

## 動作環境

- iOS 17.0 以上の iPhone
- ビルド：Xcode 16 以降（Xcode Cloud の「Latest Release」でOK）

## フォルダ構成

```
WinterArc.xcodeproj/        Xcode プロジェクト（共有スキーム入り）
WinterArc/
  App/                      アプリの入口・タブ
  Models/                   SwiftData のデータ（タスク・習慣・記録・目標）
  Support/                  色・日付・通知・名言などの共通処理
  Components/               山のイラスト・週カレンダーなどの部品
  Features/                 画面ごとのコード
  Assets.xcassets/          アプリアイコン・色
Config/Info.plist           追加の Info.plist 設定（暗号化申告なし・起動画面の色）
.github/workflows/          GitHub Actions（ビルド確認 / 予備のTestFlightアップロード）
docs/SETUP_XCODE_CLOUD.md   ★ Windows だけで TestFlight に届けるまでの手順
```

新しい `.swift` ファイルは `WinterArc/` フォルダの中に置くだけで自動的にビルド対象になります（Xcode 16 の「同期フォルダ」機能）。

## はじめに必ず変えるところ

`WinterArc.xcodeproj/project.pbxproj` の中の次の2か所（Debug / Release で各2回、計4か所）：

```
DEVELOPMENT_TEAM = "";                              ← あなたの Team ID
PRODUCT_BUNDLE_IDENTIFIER = com.example.winterarc;  ← あなた専用の Bundle ID
```

詳しくは [docs/SETUP_XCODE_CLOUD.md](docs/SETUP_XCODE_CLOUD.md) を見てください。
