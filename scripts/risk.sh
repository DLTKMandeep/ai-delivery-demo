#!/usr/bin/env bash
# Prints low, medium or high for the changes between a base ref and HEAD.
set -euo pipefail
BASE="${1:-origin/main}"
POLICY=".github/risk-policy.txt"
FILES=$(git diff --name-only "$BASE"...HEAD)
LINES=$(git diff --numstat "$BASE"...HEAD | awk '{a+=$1; d+=$2} END {print a+d+0}')
MAX=$(awk -F': *' '/^medium_max_lines:/ {print $2}' "$POLICY")
MAX=${MAX:-150}
while read -r glob; do
  [ -z "$glob" ] && continue
  while read -r f; do
    [ -z "$f" ] && continue
    # shellcheck disable=SC2053
    if [[ "$f" == $glob ]]; then echo high; exit 0; fi
  done <<< "$FILES"
done < <(awk -F': *' '/^high:/ {print $2}' "$POLICY")
if [ "$LINES" -gt "$MAX" ]; then echo medium; exit 0; fi
echo low
