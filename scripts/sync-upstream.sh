#!/usr/bin/env bash
# Sync useful functional work from parent Olauncher into an Intently-facing
# branch. It intentionally never pushes: the merge sometimes needs judgement
# about what belongs to Intently and what belongs to Olauncher.

set -euo pipefail

# The remote is named `olauncher`, not the more common `upstream`: gh CLI
# treats an `upstream` remote as the base (parent) repository, which would
# send `gh pr` and `gh repo` commands at tanujnotes/Olauncher instead of
# this fork.
PARENT_REMOTE="olauncher"
PARENT_URL="https://github.com/tanujnotes/Olauncher.git"
PARENT_BRANCH="master"
SYNC_BRANCH="sync/upstream"
BASE_BRANCH="master"
TESTABLE=1

usage() {
   cat <<EOF
Usage: scripts/sync-upstream.sh [--no-test]

Creates or reuses $SYNC_BRANCH and merges $PARENT_REMOTE/$PARENT_BRANCH
into it. Use --no-test to skip the optional Gradle unit tests.
EOF
}

for arg in "$@"; do
   case "$arg" in
      --no-test) TESTABLE=0 ;;
      -h|--help) usage; exit 0 ;;
      *)
         usage
         echo
         echo "Unknown option: $arg" >/dev/stderr
         exit 1
         ;;
   esac
done

root="$(git rev-parse --show-toplevel)"
cd "$root"

if [ -n "$(git status --porcelain)" ]; then
   echo "Working tree is not clean. Commit or stash first." >/dev/stderr
   exit 1
fi

if git remote get-url "$PARENT_REMOTE" >/dev/null 2>&1; then
   echo "Updating $PARENT_REMOTE remote."
else
   git remote add "$PARENT_REMOTE" "$PARENT_URL"
   echo "Added $PARENT_REMOTE remote: $PARENT_URL"
fi

git fetch origin --prune
git fetch "$PARENT_REMOTE" --tags

git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

if git show-ref --verify --quiet "refs/heads/$SYNC_BRANCH"; then
   git checkout "$SYNC_BRANCH"
   if ! git merge-base --is-ancestor "$BASE_BRANCH" "$SYNC_BRANCH"; then
      git merge --ff-only "$BASE_BRANCH"
   fi
else
   git checkout -b "$SYNC_BRANCH" "$BASE_BRANCH"
fi

echo "Merging $PARENT_REMOTE/$PARENT_BRANCH into $SYNC_BRANCH..."
if ! git merge "$PARENT_REMOTE/$PARENT_BRANCH" --no-edit; then
   echo "Merge conflict. Resolve it, then ./scripts/sync-upstream.sh again." >/dev/stderr
   echo "If the conflict is gone, commit the merge to finish it." >/dev/stderr
   exit 1
fi

echo
echo "Ready to review on $(git branch --show-current)."
if [ "$TESTABLE" -eq 1 ] && [ -x "./gradlew" ] && command -v java >/dev/null 2>&1; then
   echo "Running optional unit tests."
   ./gradlew testDebugUnitTest
else
   echo "Skipped optional unit tests."
fi

echo
echo "When reviewed, push and open a pull request: git push -u origin $SYNC_BRANCH"
