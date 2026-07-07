APK packaging helper for the Capacitor Android APK flow
======================================================

This branch contains a minimal APK signing helper and a restored Capacitor scaffold. It is not yet a complete build-ready Android app.

Included files:
- `.gitignore`
- `README_APK.md`
- `package.json`
- `capacitor.config.json`
- `www/index.html`
- `www/manifest.webmanifest`
- `scripts/generate-sign-apk.ps1`

Prerequisites
-------------
- Node.js (>=16)
- Java JDK (11+)
- Android SDK (via Android Studio or command-line SDK)
- `npx` available in your PATH

Build flow
----------
1) Install dependencies:

```bash
npm install
```

2) Initialize Capacitor (only first time):

```bash
npm run cap:init
```

3) Add Android platform:

```bash
npm run cap:add-android
```

4) Copy web assets into the native project:

```bash
npm run cap:copy
```

5) Open the Android project in Android Studio and build an APK/AAB:

```bash
npm run cap:open-android
```

Alternate CLI build:

```bash
npm run build:android
```

Signing the APK
----------------
After building the unsigned release APK, sign it with the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -GenerateKeystore -StorePass '<storepass>' -KeyPass '<keypass>'

powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -SignApk -StorePass '<storepass>' -KeyPass '<keypass>'
```

The helper expects the unsigned APK here:

`android/app/build/outputs/apk/release/app-release-unsigned.apk`

and produces the signed output here:

`android/app/build/outputs/apk/release/app-release.apk`

Manual signing alternative:

```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.jks android/app/build/outputs/apk/release/app-release-unsigned.apk alias_name
zipalign -v 4 android/app/build/outputs/apk/release/app-release-unsigned.apk android/app/build/outputs/apk/release/app-release.apk
```

Repository status
-----------------
This repo now includes a minimal PWA scaffold under `www/` and a Capacitor config.

Missing pieces:
- a built `android/` platform with `app/` sources
- an actual unsigned APK at `android/app/build/outputs/apk/release/app-release-unsigned.apk`
- GitHub Actions workflow files for CI

GitHub PR base guidance
-----------------------
Remote branches:
- `master`
- `apk-packaging`

The repository default branch appears to be `apk-packaging` on the remote.

If `master` is the intended stable base, create your PR with `base: master` and `head: apk-packaging`.

Recommended next step
---------------------
Use the restored `npm` and Capacitor commands to create the Android platform, then build the unsigned APK and sign it with `scripts/generate-sign-apk.ps1`.
