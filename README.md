# PRnote Android App

PRnote is a minimal Android-focused Capacitor project. The native Android wrapper lives in `android/`, and the editable app UI lives in `src/`.

## Screenshots

<table>
<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/0f638549-1e02-44e4-b2ad-e6e52b1ad1b5" width="260"/>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/8b5db3a3-0de1-41f8-b298-18374aabecbe" width="260"/>
</td>
</tr>

<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/0db36fe3-59d7-42b4-8711-c15c5e24203e" width="260"/>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/abf142d5-e40f-4b50-964e-d025ec6e3548" width="260"/>
</td>
</tr>

<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/6d805cad-7d5b-4721-bb72-13c4ab384e0b" width="260"/>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/af10392b-cbbf-46ef-b0fc-b89728e2dce2" width="260"/>
</td>
</tr>

<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/a200eed3-a8fc-4963-9e29-33b1f09e5b91" width="260"/>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/6018e4b0-cd24-4fea-95a6-89960c4ca843" width="260"/>
</td>
</tr>

<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/10927a35-73e5-4aa2-8256-d1b13f7d0cfc" width="260"/>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/b6572bc2-43b6-4523-8595-11c697cd8aac" width="260"/>
</td>
</tr>
</table>

## Requirements

* Node.js 22+
* npm
* Java 21
* Android SDK / Android Studio
* `adb` for device installs

## Main Commands

Start the fast web preview while editing UI:

```sh
npm run dev
```

Sync web changes into the Android project:

```sh
npm run android:sync
```

Build the Android debug APK:

```sh
cd android
./gradlew assembleDebug
```

Install the debug APK on a connected phone:

```sh
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Daily Android Workflow

```sh
npm run android:sync
cd android
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Kept In This Repo

* `android/` for the native Android project
* `src/` for the app screens, hooks, and core UI
* `public/favicon.ico`
* `capacitor.config.ts`
* Vite, TypeScript, Tailwind, and npm config files needed to keep editing the app

## Notes

* After changing app code in `src/`, run `npm run android:sync` before rebuilding the APK.
* This repo was trimmed to remove test files, Playwright files, Bun lockfiles, and unused generated UI components.

## Firebase Backup Setup

* Copy `.env.example` to `.env` and fill in your Firebase web app values.
* In Firebase Console, enable `Authentication > Sign-in method > Google`.
* In Firestore, create a database for note backups.
* Keep `localhost` in Firebase Auth authorized domains so the Capacitor app can complete the hosted auth flow.
