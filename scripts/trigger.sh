#!/usr/bin/env bash
# Starts the agent for a story without Jira automation. Usage: scripts/trigger.sh PROJ-1
set -euo pipefail
KEY="${1:?Usage: scripts/trigger.sh PROJ-1}"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api "repos/$REPO/dispatches" -f event_type=jira-ready -f "client_payload[key]=$KEY"
echo "Sent jira-ready for $KEY to $REPO. Watch: gh run watch"
