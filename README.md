# My Scheduler

### Table of contents

- [My Scheduler](#my-scheduler)
    - [Table of contents](#table-of-contents)
  - [デプロイ／実行手順](#デプロイ実行手順)
  - [注意点・差し替え箇所](#注意点差し替え箇所)
  - [Quick start](#quick-start)
  - [Cloud Functions](#cloud-functions)
  - [Notes](#notes)
  - [Structure of collections and documents](#structure-of-collections-and-documents)
  - [Directory structure](#directory-structure)

## デプロイ／実行手順

1. Firebase プロジェクトを作成する（console.firebase.google.com）。

2. Firebase CLI をインストールしてログインする。

3. Flutter アプリ側：
   - `flutter pub get`
   - Firebase config を各プラットフォームに設定（google-services.json / GoogleService-Info.plist / web firebase config）。
   - firebase_auth は匿名ログインやメールログインを使うが、今回は簡単に匿名ログインを推奨（テスト用）。

4. Cloud Functions：
   - cd functions
   - npm install
   - firebase deploy --only functions

5. Cloud Scheduler：
   - GCP コンソールから Cloud Scheduler ジョブを作成し、HTTP ターゲットで `https://<region>-<project>.cloudfunctions.net/notifyDueSchedules` を毎分（または5分毎）で実行する設定にする。
   - このために Blaze（課金情報登録）が必要になるが、使用量は微小で済む。

6. Firestore へユーザーの meta/settings/lineNotifyToken を保存（手動でも UI を作って設定可能）。
  - 例：
    ```
    users/{yourUserId}/meta/settings = {
      lineNotifyToken: "YOUR_LINE_NOTIFY_TOKEN"
    }
    ```

## 注意点・差し替え箇所

- Firebase config や lineNotifyToken は実際に運用する前に必ず差し替えてください。公開リポジトリにトークンを置かないでください。

- Cloud Function の実行タイミングと notifyAtUtc の計算が一致するように、クライアント側で notifyAtUtc を UTC に直して保存する必要があります（サンプル実装で行っています）。

- 本レスポンスでは最小限の UI とサービス層を提示しました。残りの画面（Calendar の複数日選択で一括プリセット適用、プリセット作成 UI、完全な編集フォーム、認証 UI など）は同様のパターンで追加できます。必要ならそのまま続けて完全実装を出力します。


## Quick start
1. Create Firebase project and enable Firestore, Authentication (Anonymous).
2. Add Firebase config to Flutter app (google-services.json / GoogleService-Info.plist or use flutterfire CLI).
3. Run `flutter pub get`.
4. Start app with `flutter run -d chrome` (web) or device.

## Cloud Functions
- Deploy functions in `functions/` directory (see previous message).
- Create Cloud Scheduler job to call the function every minute (or every 5 minutes).
- Store your LINE Notify token in Firestore: users/{uid}/meta/settings.lineNotifyToken

## Notes
- UI and comments are in English.
- Data model uses UTC for `notifyAtUtc`.
- For local testing without Scheduler: you can run the Cloud Function manually via HTTP, or trigger from Cloud Functions emulator.

## Structure of collections and documents

users/{userId}/schedules/{scheduleId}
  - title: string
  - date: string (YYYY-MM-DD)
  - notifyTime: string (HH:mm)
  - notifyAtUtc: timestamp (timestamp, for querying)
  - lineMessage: string
  - memo: string
  - disabled: boolean
  - presetSourceId: string|null
  - createdAt: timestamp
  - deletedAt: timestamp|null (soft delete)

users/{userId}/presets/{presetId}
  - name: string
  - items: array of { title, notifyTime, lineMessage, memo, disabled }
  - createdAt: timestamp
  - deletedAt: timestamp|null

## Directory structure

```
project-root/
├─ flutter_app/
│  ├─ pubspec.yaml
│  ├─ lib/
│  │  ├─ main.dart
│  │  ├─ models/
│  │  │  ├─ schedule_item.dart
│  │  │  └─ preset.dart
│  │  ├─ services/
│  │  │  ├─ firestore_service.dart
│  │  ├─ pages/
│  │  │  ├─ home_page.dart
│  │  │  ├─ calendar_page.dart
│  │  │  ├─ presets_page.dart
│  │  │  └─ settings_page.dart
│  │  ├─ widgets/
│  │  │  └─ schedule_tile.dart
│  └─ android/ ios/ web/ ...
├─ functions/                      # Firebase Cloud Functions
│  ├─ package.json
│  └─ index.js
└─ README.md
```
