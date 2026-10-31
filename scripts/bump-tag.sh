#!/usr/bin/env bash
# Sets the app image in deploy/rollout.yaml. Usage: bump-tag.sh ghcr.io/owner/repo:sha
set -euo pipefail
NEW="${1:?Usage: bump-tag.sh IMAGE:TAG}"
sed -i.bak -E "s#^([[:space:]]*image:[[:space:]]*).*#\1${NEW}#" deploy/rollout.yaml
rm -f deploy/rollout.yaml.bak
grep -n "image:" deploy/rollout.yaml
