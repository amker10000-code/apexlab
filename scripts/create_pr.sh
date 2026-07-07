#!/usr/bin/env bash
# Create a branch for PR from master and push to origin
# Usage: ./scripts/create_pr.sh apk-packaging

set -euo pipefail
BRANCH=${1:-apk-packaging}
BASE=${2:-master}

git fetch origin
# create branch from base
git checkout -B "$BRANCH" "origin/$BASE"
# add any outstanding changes
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Prepare $BRANCH for PR"
fi
git push --set-upstream origin "$BRANCH" --force-with-lease
echo "Pushed branch $BRANCH. Create PR at: https://github.com/$(git remote get-url origin | sed -E 's#.*github.com[:/](.+)\.git#\1#')/compare/$BASE...$BRANCH"
