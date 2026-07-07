#!/usr/bin/env bash
# Encode a keystore to base64 for GitHub Secret upload
# Usage: ./encode-keystore.sh my-release-key.jks > keystore.base64

set -euo pipefail
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <keystore-file>" >&2
  exit 2
fi
if [ ! -f "$1" ]; then
  echo "Keystore not found: $1" >&2
  exit 3
fi
base64 -w 0 "$1"
