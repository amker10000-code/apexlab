Title: chore(apk): add APK signing helper, CI workflow, and Capacitor scaffold

This PR adds a minimal Capacitor scaffold, a PowerShell helper to sign and align APKs, helper scripts to prepare keystore secrets, and a GitHub Actions workflow to build (unsigned) Android APKs.

Summary of changes:
- Added `scripts/generate-sign-apk.ps1` (signs and aligns a release APK)
- Added helpers: `tools/encode-keystore.sh`, `tools/encode-keystore.ps1`, `scripts/create_pr.sh`, `scripts/capacitor_helpers.sh`
- Added minimal `package.json`, `capacitor.config.json`, and `www/` scaffold to restore Capacitor commands
- Added `.github/workflows/build-android.yml` to build unsigned APKs in CI
- Updated `README_APK.md` to reflect the current repo contents and usage

Notes:
- The repository currently needs a generated `android/` platform and a built unsigned APK; run `npm run cap:init` and `npm run cap:add-android`, then build the release APK locally or in CI.
- Creating the GitHub PR itself requires web confirmation; open the compare page and create the PR from there.

How to test locally:
1) Install dependencies: `npm install`
2) Initialize Capacitor and add Android: `npm run cap:init && npm run cap:add-android`
3) Build the release APK: `npm run build:android`
4) Sign the APK using PowerShell helper: `powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -SignApk -StorePass '<storepass>' -KeyPass '<keypass>'`
