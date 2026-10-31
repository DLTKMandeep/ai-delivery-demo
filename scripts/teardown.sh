#!/usr/bin/env bash
# Removes the local cluster. Add --repo to delete the GitHub repo too.
set -euo pipefail
kind delete cluster --name "${CLUSTER:-ai-demo}" || true
if [ "${1:-}" = "--repo" ]; then
  REPO="$(gh api user -q .login)/${REPO_NAME:-ai-delivery-demo}"
  read -rp "Delete https://github.com/$REPO for good? Type the repo name to confirm: " c
  [ "$c" = "${REPO_NAME:-ai-delivery-demo}" ] && gh repo delete "$REPO" --yes
fi
