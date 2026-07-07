#!/usr/bin/env bash
# Minimal helper to initialize Capacitor and add Android platform
set -euo pipefail
if [ ! -f package.json ]; then
  echo "package.json missing. Run this from project root." >&2
  exit 2
fi
npm install
npx cap init "ApexLab" "com.apexlab.app" --web-dir=www || true
npx cap add android || true
npx cap copy
echo "Capacitor commands completed. Open Android Studio with: npm run cap:open-android" 
