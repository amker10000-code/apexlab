Converting this PWA to an Android APK (Capacitor)

Prerequisites (on your machine):
- Node.js (>=16)
- Java JDK (11+)
- Android SDK (via Android Studio or command-line SDK)
- Gradle (Android Studio manages this automatically)

Quick scaffold + build steps (run from project root):

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

4) Copy web assets into native project:

```bash
npm run cap:copy
```

5) Open Android project in Android Studio and build an APK/AAB:

```bash
npm run cap:open-android
# then use Android Studio > Build > Build Bundle(s) / APK(s)
```

Alternate CLI build (advanced, requires Android SDK + gradle in PATH):

```bash
cd android
./gradlew assembleRelease
# output: android/app/build/outputs/apk/release/app-release-unsigned.apk
```

Signing the APK with the included helper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -SignApk -StorePass '<storepass>' -KeyPass '<keypass>'
```

This produces the final signed and aligned APK at:

`android/app/build/outputs/apk/release/app-release.apk`

If you prefer the manual commands, use:

```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.jks android/app/build/outputs/apk/release/app-release-unsigned.apk alias_name
zipalign -v 4 android/app/build/outputs/apk/release/app-release-unsigned.apk app-release.apk
```

Notes:
- This repository is a simple PWA (no bundling). Capacitor will use the project root as the web directory.
- If you prefer a TWA (Trusted Web Activity) approach, see Bubblewrap (pwabuilder) for a similar flow.
- I can run the `npm` and `npx cap` steps here if you want me to attempt them; building the final APK requires Android SDK/JDK which may not be available in this environment.

TWA (Trusted Web Activity) option
---------------------------------
If you prefer packaging the PWA as a TWA (no native webview wrapper), use Bubblewrap to generate an Android project that hosts your PWA as a TWA.

Install Bubblewrap:

```bash
npm install -g @bubblewrap/cli
bubblewrap init --manifest=https://your-site.example/manifest.webmanifest
bubblewrap build
```

Bubblewrap will produce an Android project you can open in Android Studio. TWAs are a good fit if your PWA is already served from a secure, reliable host and you prefer minimal native code.

CI signing
----------
The included GitHub Actions workflow attempts to sign and align the APK if you provide the following repository secrets:

- `APK_KEYSTORE_BASE64` — base64-encoded keystore file contents
- `APK_KEYSTORE_PASSWORD` — keystore password
- `APK_KEY_ALIAS` — key alias
- `APK_KEY_PASSWORD` — key password

Add these as repository secrets and re-run the workflow; the signed APK artifact will be uploaded as `app-release-signed-apk`.

CI Build (GitHub Actions):

You can use the included GitHub Actions workflow to build an unsigned APK automatically. Push this branch to GitHub and run the `Build Android APK` workflow (or trigger it via Actions > Run workflow).

After the workflow completes, download the `app-release-apk` artifact from the workflow run. The APK will be unsigned — sign and align it locally or via your CI secrets before distribution.

Signing example (local):

```bash
# sign
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.jks android/app/build/outputs/apk/release/app-release-unsigned.apk alias_name
# align
zipalign -v 4 android/app/build/outputs/apk/release/app-release-unsigned.apk app-release.apk
```

Helper scripts
--------------
I added helper scripts under `tools/` and `scripts/`:

- `tools/encode-keystore.sh` — base64-encodes a keystore for easy upload to GitHub Secrets.
- `tools/encode-keystore.ps1` — PowerShell equivalent for Windows.
- `scripts/create_pr.sh` — creates a local branch, commits changes, and prints push instructions.
- `scripts/capacitor_helpers.sh` — interactive helper to run `npm install`, initialize Capacitor, add Android, and copy assets.
- `scripts/generate-sign-apk.ps1` — generates a local keystore, signs the Capacitor release APK, and aligns the final APK. It also auto-detects the SDK build-tools path using `android/local.properties`.

Usage examples:

```bash
chmod +x tools/encode-keystore.sh scripts/create_pr.sh scripts/capacitor_helpers.sh
./tools/encode-keystore.sh my-release-key.jks > keystore.base64
# copy contents of keystore.base64 into GitHub secret `APK_KEYSTORE_BASE64`

# create branch and commit
./scripts/create_pr.sh

# interactive Capacitor setup
./scripts/capacitor_helpers.sh
```

PowerShell signing helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -GenerateKeystore
powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -SignApk -StorePass '<storepass>' -KeyPass '<keypass>'
```
