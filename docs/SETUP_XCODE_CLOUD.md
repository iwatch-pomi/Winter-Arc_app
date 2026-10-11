# Windows だけで iPhone に届けるまでの手順（Xcode Cloud → TestFlight）

このドキュメントは「Mac を持っていない／Windows だけ」の環境で、
このリポジトリのアプリを **Xcode Cloud でアーカイブ → TestFlight で iPhone にインストール** するまでの手順です。

> ⚠️ 最初に知っておいてほしい大事なこと
>
> Apple の公式ドキュメントでは、**Xcode Cloud の「最初の1回のセットアップ（製品の登録と最初のワークフロー作成）」は Xcode（＝Mac）から行う** ことになっています。
> 一度セットアップが終われば、そのあとのワークフローの編集・ビルド開始・結果確認・TestFlight 配信は **App Store Connect（ブラウザ）だけで完結** し、Windows から GitHub に push するだけで自動でビルドされます。
>
> そのため、次のどちらかを選んでください。
>
> | ルート | 内容 | Mac |
> | --- | --- | --- |
> | **A. Xcode Cloud（おすすめ・本命）** | 最初の1回だけレンタルMac（1時間程度）か知人のMacで設定。あとは Windows だけで運用 | 最初の1回だけ必要 |
> | **B. GitHub Actions（予備ルート）** | このリポジトリに入っている `testflight.yml` を使う。Apple の API キーで署名・アップロード | 一切不要 |
>
> どちらも最後は同じ「TestFlight で iPhone にインストール」です。A がうまくいかないときは B を使ってください。

---

## 0. 全体の流れ

```
[Windows] コードを編集して GitHub に push
     ↓
[Xcode Cloud] 自動でビルド → アーカイブ → 署名
     ↓
[App Store Connect] TestFlight にビルドが届く
     ↓
[iPhone] TestFlight アプリからインストール
```

---

## 1. 事前準備（共通）

### 1-1. Apple Developer Program に登録する

- https://developer.apple.com/programs/ から登録（有料・年額。料金は公式ページで確認してください）
- Windows の場合は、iPhone の「Apple Developer」アプリから登録するのが簡単です
- 登録完了まで数日かかることがあります
- Xcode Cloud には Apple Developer Program のメンバーシップに **毎月 25 時間分の無料ビルド時間** が含まれています（2026年時点。最新の条件は公式で確認してください）

### 1-2. 契約に同意しておく

https://developer.apple.com/account にログインし、画面上部に「契約を確認して同意してください」のような表示が出ていたら同意します。
（未同意だと Xcode Cloud やアプリ登録でエラーになります）

### 1-3. Team ID を調べる

1. https://developer.apple.com/account を開く
2. 「メンバーシップの詳細（Membership details）」を開く
3. **チームID（Team ID）**：`A1B2C3D4E5` のような英数字10文字 → メモする

### 1-4. Bundle ID（アプリの識別子）を決めて登録する

Bundle ID は世界で一意である必要があります。例：`com.<あなたの名前>.winterarc`

1. https://developer.apple.com/account/resources/identifiers/list を開く
2. 「＋」→「App IDs」→「Continue」→「App」→「Continue」
3. Description：`Winter Arc`
4. Bundle ID：「Explicit」を選んで `com.<あなたの名前>.winterarc` を入力
5. Capabilities は何もチェックしなくてOK（このアプリは追加機能を使いません。通知はローカル通知なので Push Notifications も不要）
6. 「Continue」→「Register」

### 1-5. プロジェクトに Team ID と Bundle ID を書き込む（Windows / ブラウザでOK）

GitHub のブラウザ画面で `WinterArc.xcodeproj/project.pbxproj` を開き、鉛筆アイコン（Edit）で編集します。
（または VS Code などで編集して push）

次の行を **それぞれ2か所ずつ（Debug と Release）** 書き換えます。

```diff
- DEVELOPMENT_TEAM = "";
+ DEVELOPMENT_TEAM = A1B2C3D4E5;

- PRODUCT_BUNDLE_IDENTIFIER = com.example.winterarc;
+ PRODUCT_BUNDLE_IDENTIFIER = com.yourname.winterarc;
```

> 💡 ブラウザで `Ctrl + F` で `DEVELOPMENT_TEAM` と `PRODUCT_BUNDLE_IDENTIFIER` を検索すると見つけやすいです。
> 書き換えたら「Commit changes」でコミットします。

### 1-6. App Store Connect にアプリを登録する

1. https://appstoreconnect.apple.com/ →「アプリ」
2. 左上の「＋」→「新規App」
3. 入力内容
   - プラットフォーム：**iOS**
   - 名前：`Winter Arc`（App Store 全体で重複不可。使われていたら `Winter Arc - 冬の自己管理` などに変更。あとから変えられます）
   - プライマリ言語：日本語
   - バンドルID：1-4 で登録したものを選択
   - SKU：自由な文字列（例：`winterarc001`）
   - ユーザアクセス：フルアクセス
4. 「作成」

---

## 2. ルートA：Xcode Cloud で配信する（本命）

### 2-1. 【最初の1回だけ Mac が必要】Xcode Cloud のセットアップ

Mac の用意方法の例：

- レンタル Mac（時間貸しのクラウド Mac サービス。Windows からリモートデスクトップで操作できます。1時間程度で終わります）
- 家族・知人の Mac、学校・職場の Mac

Mac 上での作業：

1. App Store から **Xcode（最新版）** をインストールして起動
2. Xcode →「Settings…」→「Accounts」→「＋」→ Apple ID でサインイン（自分の開発者アカウント）
3. 「Clone Git Repository…」（または「Integrate」メニュー →「Clone…」）で
   `https://github.com/iwatch-pomi/Winter-Arc_app.git` をクローン
   - ブランチは Xcode Cloud でビルドしたいもの（例：`main`）を選ぶ
4. `WinterArc.xcodeproj` を開く
5. 左のプロジェクトナビゲータで「WinterArc」ターゲット →「Signing & Capabilities」を開き、
   - 「Automatically manage signing」にチェックが入っていること
   - Team が自分のチームになっていること
   - Bundle Identifier が 1-4 のものになっていること
   を確認（エラーが出ていなければOK）
6. メニュー「Integrate」→「Create Workflow…」
   （または左のレポートナビゲータ → 「Cloud」タブ →「Get Started」）
7. 製品（Product）として「WinterArc」を選んで「Next」
8. ワークフローの編集画面が出るので、次のように設定（あとでブラウザからも変更できます）
   - **General**：名前 `TestFlight`
   - **Environment**：Xcode Version = `Latest Release`、macOS Version = `Latest Release`
   - **Start Conditions**：「Branch Changes」→ Source Branch = `main`（push するたびに自動ビルド）
   - **Actions**：「＋」→「Archive」→ Platform = iOS、Deployment Preparation = **TestFlight (Internal Testing Only)**
   - **Post-Actions**：「＋」→「TestFlight Internal Testing」→ グループを追加（なければ後で作成）
9. 「Grant Access」で GitHub へのアクセスを許可
   - ブラウザが開くので GitHub にログインし、「Install」で `Winter-Arc_app` リポジトリへのアクセスを許可
10. App Store Connect のアプリ（1-6 で作ったもの）と紐付ける確認が出たら選択
11. 「Start Build」で最初のビルドを開始

これで Mac での作業は終わりです。以降は Mac は不要です。

### 2-2. 【以降は Windows だけ】ブラウザでビルドを確認する

1. https://appstoreconnect.apple.com/ →「アプリ」→「Winter Arc」
2. 上部タブの **「Xcode Cloud」** を開く
3. 「ビルド」に実行中・完了したビルドが表示されます
   - 失敗した場合は、ビルドをクリック →「Archive - iOS」→ ログ（Logs）でエラー内容を確認できます
4. ワークフローの変更も「Xcode Cloud」→「ワークフローを管理（Manage Workflows）」からブラウザで行えます
5. 手動でビルドしたいときは「ビルドを開始（Start Build）」

### 2-3. いつもの開発サイクル

```
Windows でコード修正 → GitHub に push（または main にマージ）
→ Xcode Cloud が自動でビルド（10〜20分ほど）
→ TestFlight に新しいビルドが届く
→ iPhone の TestFlight アプリで「アップデート」
```

ビルド番号（CFBundleVersion）は Xcode Cloud が自動で連番を振るので、自分で増やす必要はありません。
アプリのバージョン（1.0 → 1.1 など）を上げたいときは `project.pbxproj` の `MARKETING_VERSION` を変更してください。

---

## 3. ルートB：GitHub Actions で配信する（Mac 不要の予備ルート）

`.github/workflows/testflight.yml` を手動実行すると、GitHub の macOS マシン上でアーカイブ → 署名 → App Store Connect へのアップロードまで行います。

> 注意：プライベートリポジトリの場合、GitHub Actions の macOS 実行時間は無料枠の消費が大きいです（Linux の10倍換算）。1回あたり10〜15分程度です。

### 3-1. App Store Connect API キーを作る

1. https://appstoreconnect.apple.com/access/integrations/api を開く
   （「ユーザとアクセス」→「統合」→「App Store Connect API」）
2. 初回は「アクセスをリクエスト」→ 同意
3. 「チームキー」の「＋（APIキーを生成）」
   - 名前：`GitHub Actions`
   - アクセス：**Admin**（自動署名でクラウド管理証明書を使うために必要）
4. 生成後に表示される次の3つをメモ
   - **キーID**（Key ID）
   - **Issuer ID**（ページ上部に表示）
   - **API キー（.p8 ファイル）をダウンロード**（⚠️ 1回しかダウンロードできません）

### 3-2. GitHub に Secrets を登録する

GitHub のリポジトリ →「Settings」→「Secrets and variables」→「Actions」→「New repository secret」で、以下の5つを登録します。

| Name | 値 |
| --- | --- |
| `ASC_KEY_ID` | キーID |
| `ASC_ISSUER_ID` | Issuer ID |
| `ASC_KEY_P8` | ダウンロードした `.p8` ファイルをメモ帳で開き、`-----BEGIN PRIVATE KEY-----` から `-----END PRIVATE KEY-----` までをすべてコピー＆ペースト |
| `DEVELOPMENT_TEAM` | Team ID（1-3） |
| `BUNDLE_ID` | Bundle ID（1-4） |

> ⚠️ `.p8` ファイルはリポジトリに絶対にコミットしないでください（`.gitignore` で除外済み）。

### 3-3. 実行する

1. GitHub のリポジトリ →「Actions」タブ
2. 左の「Upload to TestFlight (GitHub Actions)」→「Run workflow」→ ブランチを選んで実行
3. 成功すると、数分〜30分ほどで App Store Connect の「TestFlight」タブにビルドが表示されます

> ルートAと併用する場合、ビルド番号が重ならないようにこちらは `1000 + 実行番号` を使っています。

---

## 4. TestFlight で iPhone にインストールする（共通）

### 4-1. テスターを登録する（初回のみ）

1. App Store Connect →「アプリ」→「Winter Arc」→「TestFlight」タブ
2. 左の「内部テスト」の「＋」→ グループ名（例：`自分`）を作成
3. 「テスター」の「＋」→ 自分の Apple ID（App Store Connect のユーザ）を追加
4. 「ビルド」の「＋」から配信したいビルドを追加
   （ルートAで Post-Action を設定していれば自動で追加されます）

> 「輸出コンプライアンス情報が不足」と表示されることがありますが、このプロジェクトは `Config/Info.plist` で
> 「独自の暗号化を使っていない（ITSAppUsesNonExemptEncryption = NO）」と申告済みなので、通常は聞かれません。

### 4-2. iPhone 側

1. iPhone で App Store から **TestFlight** アプリをインストール
2. 4-1 で登録した Apple ID と同じ Apple ID で iPhone にサインインしていることを確認
3. 招待メールのリンク、または TestFlight アプリを開くと「Winter Arc」が表示される
4. 「インストール」

内部テストのビルドは90日間有効です。新しいビルドが届くと TestFlight アプリに「アップデート」が出ます。

---

## 5. よくあるエラーと対処

| 症状 | 原因と対処 |
| --- | --- |
| `No profiles for '...' were found` / `Signing requires a development team` | `project.pbxproj` の `DEVELOPMENT_TEAM` が空のまま。1-5 を確認 |
| `No App ID ... matching bundle identifier` | Bundle ID が未登録、または `project.pbxproj` と App Store Connect のものが違う。1-4・1-6 を確認 |
| Xcode Cloud で `scheme ... is not shared` | `WinterArc.xcodeproj/xcshareddata/xcschemes/WinterArc.xcscheme` を消していないか確認 |
| Xcode Cloud で project の読み込みエラー | Environment の Xcode Version を `Latest Release`（Xcode 16 以降）にする。このプロジェクトは Xcode 16 の形式です |
| `The bundle version must be higher than the previously uploaded version` | ビルド番号の重複。Xcode Cloud なら自動で連番。ルートBは再実行すれば番号が増えます |
| 「契約に同意する必要があります」 | 1-2 を実施 |
| TestFlight にビルドが出てこない | アップロード後の処理に10〜30分かかることがあります。メールで「処理が完了しました」と届くまで待つ |
| GitHub の「Build check」が赤い | Actions タブ → 失敗したジョブ →「Build (iOS, no signing)」のログに `error:` 行が出ています。そのファイルと行を修正して push |

---

## 6. 参考リンク

- Xcode Cloud を始める（Apple）: https://developer.apple.com/xcode-cloud/get-started/
- 最初の Xcode Cloud ワークフローを設定する（Apple）: https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow
- TestFlight（Apple）: https://developer.apple.com/testflight/
