#!/usr/bin/env bash
# One-shot setup for the AI-driven development and delivery demo.
# Run from the repo folder:  ./setup.sh
# Safe to re-run: every step checks what already exists.
set -euo pipefail

REPO_NAME="${REPO_NAME:-ai-delivery-demo}"
CLUSTER="${CLUSTER:-ai-demo}"
JIRA_PROJECT="${JIRA_PROJECT:-PROJ}"
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ROLLOUTS_MANIFEST="https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml"

bold() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31mStopped:\033[0m %s\n' "$*" >&2; exit 1; }
ask()  { # ask VAR "Prompt" [secret]
  local var="$1" prompt="$2" secret="${3:-}"
  if [ -n "${!var:-}" ]; then ok "$var taken from your environment"; return; fi
  # shellcheck disable=SC2229  # reads into the variable named by $var
  if [ -n "$secret" ]; then read -rsp "  $prompt: " "$var"; echo; else read -rp "  $prompt: " "$var"; fi
  [ -n "${!var}" ] || die "$var is required"
  export "${var?}"
}

cd "$(dirname "$0")"

# ---------------------------------------------------------------- 1. tools
bold "1/9  Checking tools"
NEED=(git gh node npm jq kind kubectl)
MISSING=()
for t in "${NEED[@]}"; do command -v "$t" >/dev/null 2>&1 || MISSING+=("$t"); done
if [ ${#MISSING[@]} -gt 0 ]; then
  if command -v brew >/dev/null 2>&1; then
    warn "Installing with Homebrew: ${MISSING[*]}"
    brew install "${MISSING[@]}"
  else
    die "Missing: ${MISSING[*]}. Install them (or Homebrew, then re-run). Part 0 of the tutorial shows how."
  fi
fi
if ! command -v kubectl-argo-rollouts >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
  brew install argoproj/tap/kubectl-argo-rollouts || warn "Argo Rollouts kubectl plugin not installed (optional, used to watch the canary)"
fi
docker info >/dev/null 2>&1 || die "Docker is not running. Install Docker Desktop, start it, then re-run."
ok "git, gh, node, jq, kind, kubectl and Docker are ready"

# ---------------------------------------------------------------- 2. GitHub login
bold "2/9  GitHub login"
gh auth status >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
SCOPES=$(gh auth status --hostname github.com 2>&1 | grep -i "scopes" || true)
if ! grep -q "workflow" <<< "$SCOPES" || ! grep -Eq "(read|write):packages" <<< "$SCOPES"; then
  echo "  GitHub needs two extra permissions (workflow, read:packages)."
  echo "  Copy the one-time code shown below, press Enter, and approve in the browser."
  gh auth refresh --hostname github.com --scopes workflow,read:packages
fi
OWNER=$(gh api user -q .login)
REPO="$OWNER/$REPO_NAME"
ok "Signed in as $OWNER"

# ---------------------------------------------------------------- 3. repository
bold "3/9  Repository $REPO"
if [ ! -d .git ]; then
  git init -q -b main
  git add -A
  git -c user.name="$OWNER" -c user.email="$OWNER@users.noreply.github.com" commit -qm "Initial demo app"
fi
if gh repo view "$REPO" >/dev/null 2>&1; then
  ok "Repo already exists"
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$REPO.git"
else
  # Public keeps branch protection and Actions free. The demo app holds no secrets.
  gh repo create "$REPO" --public --source=. --remote=origin --push
  ok "Created https://github.com/$REPO"
fi
git push -q origin main 2>/dev/null || true
git ls-remote --exit-code --heads origin gitops >/dev/null 2>&1 || { git push -q origin main:gitops; ok "Created the gitops branch Argo CD will watch"; }
for l in ai-authored:7c3aed risk:low:16a34a risk:medium:d97706 risk:high:dc2626; do
  gh label create "${l%:*}" --repo "$REPO" --color "${l##*:}" --force >/dev/null
done
gh repo edit "$REPO" --enable-auto-merge --delete-branch-on-merge >/dev/null
gh api -X PUT "repos/$REPO/branches/main/protection" --input - >/dev/null <<JSON
{"required_status_checks":{"strict":false,"contexts":["test"]},"enforce_admins":false,
 "required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
JSON
ok "Labels, auto-merge and protection on main (CI job 'test' must pass)"

# ---------------------------------------------------------------- 4. secrets
bold "4/9  Secrets (typed values are hidden and never written to disk)"
echo "  Create a fine-grained token now if you have not:"
echo "  https://github.com/settings/personal-access-tokens/new"
echo "  Repository access: only $REPO_NAME. Permissions: Contents and Pull requests, read and write."
ask AGENT_PAT "GitHub fine-grained token (AGENT_PAT)" secret
ask ANTHROPIC_API_KEY "Anthropic API key" secret
ask JIRA_BASE_URL "Jira site URL, e.g. https://acme-learn.atlassian.net"
JIRA_BASE_URL="${JIRA_BASE_URL%/}"
ask JIRA_EMAIL "Your Atlassian email"
ask JIRA_API_TOKEN "Atlassian API token" secret
for s in AGENT_PAT ANTHROPIC_API_KEY JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN; do
  printf '%s' "${!s}" | gh secret set "$s" --repo "$REPO" >/dev/null
done
ok "Five Actions secrets stored in $REPO"

# ---------------------------------------------------------------- 5. Jira story
bold "5/9  Jira"
jira() { curl -fsS -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" "$@"; }
jira "$JIRA_BASE_URL/rest/api/3/myself" >/dev/null || die "Jira login failed. Check the site URL, email and API token."
jira "$JIRA_BASE_URL/rest/api/3/project/$JIRA_PROJECT" >/dev/null || die "Project $JIRA_PROJECT not found. Create it in Jira (Scrum template, key $JIRA_PROJECT), then re-run."
STORY_JSON=$(jq -n --arg p "$JIRA_PROJECT" '{
  fields: {
    project: {key: $p},
    summary: "Add CSV export to the sales report",
    description: {type: "doc", version: 1, content: [
      {type: "paragraph", content: [{type: "text", text: "Goal: let users download the rows currently shown in the report table as a CSV file."}]},
      {type: "paragraph", content: [{type: "text", text: "Acceptance criteria: 1) An Export CSV button sits next to the region filters. 2) The file contains a header row and the visible rows only. 3) Commas, quotes and apostrophes in names are escaped correctly. 4) A toCsv function in src/report.ts has unit tests."}]},
      {type: "paragraph", content: [{type: "text", text: "Files to change: src/report.ts, src/report.test.ts, src/App.tsx. Check: npm test and npm run typecheck."}]}
    ]},
    issuetype: {name: "Story"}
  }}')
KEY=$(jira -X POST --data "$STORY_JSON" "$JIRA_BASE_URL/rest/api/3/issue" 2>/dev/null | jq -r .key || true)
if [ -z "$KEY" ] || [ "$KEY" = "null" ]; then
  KEY=$(jira -X POST --data "$(echo "$STORY_JSON" | jq '.fields.issuetype.name="Task"')" "$JIRA_BASE_URL/rest/api/3/issue" | jq -r .key)
fi
[ -n "$KEY" ] && [ "$KEY" != "null" ] || die "Could not create the Jira story."
ok "Created $KEY: Add CSV export to the sales report ($JIRA_BASE_URL/browse/$KEY)"

# ---------------------------------------------------------------- 6. cluster
bold "6/9  Local Kubernetes cluster ($CLUSTER)"
kind get clusters 2>/dev/null | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER"
kubectl config use-context "kind-$CLUSTER" >/dev/null
ok "kubectl points at kind-$CLUSTER"

# ---------------------------------------------------------------- 7. Argo CD and Argo Rollouts
bold "7/9  Argo CD and Argo Rollouts"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -n argocd --server-side --force-conflicts -f "$ARGOCD_MANIFEST" >/dev/null
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -n argo-rollouts --server-side --force-conflicts -f "$ROLLOUTS_MANIFEST" >/dev/null
echo "  Waiting for Argo CD and Argo Rollouts to start (a few minutes the first time)..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s >/dev/null
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s >/dev/null
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=300s >/dev/null
# Check Git every 30s instead of every 3 minutes, so the demo moves quickly.
kubectl -n argocd patch configmap argocd-cm --type merge -p '{"data":{"timeout.reconciliation":"30s"}}' >/dev/null
kubectl -n argocd rollout restart statefulset/argocd-application-controller >/dev/null
kubectl -n argocd rollout restart deploy/argocd-repo-server >/dev/null
ok "Argo CD and Argo Rollouts are running"

# ---------------------------------------------------------------- 8. deploy wiring
bold "8/9  Connecting Argo CD to the gitops branch"
kubectl create namespace reports --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n reports create secret docker-registry ghcr --docker-server=ghcr.io \
  --docker-username="$OWNER" --docker-password="$(gh auth token)" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
sed "s#REPO_URL#https://github.com/$REPO.git#" argocd/application.yaml | kubectl apply -f - >/dev/null
ok "Argo CD now deploys deploy/ from the gitops branch into namespace 'reports'"

# ---------------------------------------------------------------- 9. first release
bold "9/9  First release"
# The first push to main already starts the Release workflow. Start it only if no run exists.
sleep 5
if [ -n "$(gh run list --repo "$REPO" --workflow release.yml --limit 1 --json databaseId -q '.[].databaseId' 2>/dev/null)" ]; then
  ok "Release workflow is building the first image"
else
  gh workflow run release.yml --repo "$REPO" --ref main >/dev/null 2>&1 && ok "Release workflow started (builds the first image)" || warn "Start it later with: gh workflow run release.yml"
fi

ARGO_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "(not ready yet)")
cat <<TXT

========================================================================
 Setup finished.  Story ready: $KEY
========================================================================

ONE MANUAL STEP (2 minutes, once): the Jira trigger
  Jira > Project settings > Automation > Create rule
    When:    Field value changed > Labels
    If:      JQL condition:  labels = ai-ready
    Then:    Send web request
      URL:     https://api.github.com/repos/$REPO/dispatches
      Method:  POST
      Headers: Accept = application/vnd.github+json
               Authorization = Bearer <your AGENT_PAT>   (tick "Hidden")
      Body:    Custom data:
               {"event_type":"jira-ready","client_payload":{"key":"{{issue.key}}"}}
  No time? Start the agent by hand instead:  scripts/trigger.sh $KEY

OPEN THESE BEFORE YOU PRESS RECORD (one terminal tab each)
  Argo CD UI:    kubectl -n argocd port-forward svc/argocd-server 8080:443
                 https://localhost:8080   user: admin   password: $ARGO_PW
  The app:       kubectl -n reports port-forward svc/reports-stable 8081:80
                 http://localhost:8081
  Canary view:   kubectl argo rollouts get rollout reports -n reports --watch
  Actions:       gh run watch   (or https://github.com/$REPO/actions)

RECORD
  1. In Jira, add the label  ai-ready  to $KEY.   <- the one human touch
  2. Watch: Agent run -> PR -> CI + Risk policy -> auto-merge -> Release
            -> Argo CD sync -> canary 25% > smoke test > 50% > 75% > 100%
  3. Refresh http://localhost:8081 and click Export CSV.

Full script with timings: RECORDING.md
TXT
