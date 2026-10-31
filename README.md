# AI-driven development and delivery demo (with HITL)

A real, end-to-end pipeline you can run and record. A human labels one Jira story `ai-ready`.
From there, an AI coding agent writes the code and tests, CI checks it, a risk policy decides
whether a human must review, and an approved change rolls out to a local Kubernetes cluster as a canary.

Part of the **learn4free** series by Mandeep Singh (Parts 0, 1 and 2).

```
Jira label ──▶ Agent (GitHub Actions + Claude Code) ──▶ Pull request
   ──▶ CI (typecheck, tests, build) + Risk policy ──▶ auto-merge if low risk
   ──▶ Release (build, sign, push image, bump gitops branch)
   ──▶ Argo CD sync ──▶ Argo Rollouts canary 25% ▸ smoke test ▸ 50% ▸ 75% ▸ 100%
```

## Before you start (once, about 20 minutes)

Part 0 of the tutorial walks through each of these.

1. **Accounts:** GitHub, a free Jira Cloud site with a project whose key is `PROJ`, and an Anthropic API account with billing and a spend limit.
2. **Laptop:** macOS or Linux (Windows: use WSL2) with Docker Desktop running. Homebrew is recommended; the script uses it to install anything missing.
3. **Tokens** (keep them in your password manager):
   - Anthropic API key.
   - Atlassian API token: https://id.atlassian.com/manage-profile/security/api-tokens
   - GitHub fine-grained token (`AGENT_PAT`). The script tells you when to create it, because it must be limited to the new repo. Permissions: **Contents** and **Pull requests**, read and write.

## Run it

```bash
unzip ai-delivery-demo.zip && cd ai-delivery-demo
./setup.sh
```

The script asks for the tokens (input is hidden, nothing is written to disk) and then:

| Step | What it does |
|---|---|
| 1 | Checks and installs git, gh, Node, jq, kind, kubectl, the Argo Rollouts plugin; checks Docker |
| 2 | Signs you in to GitHub with `gh` |
| 3 | Creates a **public** repo, a `gitops` branch, labels, auto-merge, and protection on `main` |
| 4 | Stores 5 Actions secrets: `AGENT_PAT`, `ANTHROPIC_API_KEY`, `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` |
| 5 | Creates the story **"Add CSV export to the sales report"** in Jira |
| 6 | Creates a local kind cluster called `ai-demo` |
| 7 | Installs Argo CD and Argo Rollouts, and sets Argo CD to check Git every 30 seconds |
| 8 | Adds a registry pull secret and the Argo CD Application |
| 9 | Makes sure the first release is building |

It finishes by printing the **one manual step** (a 2-minute Jira automation rule) and the windows to open before recording.
No time for the Jira rule? `scripts/trigger.sh PROJ-1` sends the same trigger.

Then follow **RECORDING.md**.

## What is in the repo

| Path | Purpose |
|---|---|
| `src/` | The demo app: a small React sales report with Vitest tests |
| `CLAUDE.md` | Rules the agent follows |
| `.mcp.json` | MCP servers for interactive use on your laptop |
| `.github/workflows/agent.yml` | Reads the story from Jira, runs Claude Code headless, opens the PR, comments on Jira |
| `.github/workflows/ci.yml` | Typecheck, tests, build (required check `test`) |
| `.github/workflows/risk.yml` | Scores the PR with `scripts/risk.sh`; low risk auto-merges, others wait for a human |
| `.github/risk-policy.txt` | Paths that are always high risk, and the line limit for low risk |
| `.github/workflows/release.yml` | Builds, signs (cosign keyless) and pushes the image, then bumps `deploy/` on the `gitops` branch |
| `deploy/` | Argo Rollouts canary, services and the smoke-test analysis |
| `argocd/application.yaml` | Points Argo CD at the `gitops` branch |
| `scripts/` | `risk.sh`, `bump-tag.sh`, `trigger.sh`, `teardown.sh` |

## Good to know

- **Why public?** On GitHub's free plan, branch protection (needed for safe auto-merge) only works on public repos. Secrets stay secret. If you have GitHub Pro or Team, change `--public` to `--private` in `setup.sh`.
- **Why a personal token?** Actions started by the built-in token do not start other workflows, so the agent's PR would never run CI. `AGENT_PAT` fixes that. Keep it limited to this one repo and give it an expiry date.
- **Cost:** each agent run uses some Anthropic API credit. Set a monthly spend limit in the Anthropic console.
- **Local models:** this demo uses the Claude API because it is the most reliable for a first live run. Part 2 shows how to switch to Ollama on a self-hosted GPU runner.
- **Safety:** the agent may only edit `src/`. Anything touching workflows, deploy files, scripts or dependencies is scored high risk and waits for a human.

## Troubleshooting

| Problem | Fix |
|---|---|
| Agent run fails at "Read the story" | Check `JIRA_BASE_URL` has no trailing path, and the Atlassian token and email match |
| PR opens but CI never starts | `AGENT_PAT` is missing, expired, or lacks Contents/Pull requests write |
| PR stays open after CI passes | It was scored medium or high (see the PR comment); merge it yourself |
| Pods show `ImagePullBackOff` | Run `gh auth refresh -s read:packages`, then re-run `./setup.sh` |
| Argo CD shows nothing | Wait for the first Release run to finish, then refresh the app in the UI |
| Canary stuck at 25% | The smoke test failed: `kubectl argo rollouts get rollout reports -n reports` shows why |

## Clean up

```bash
scripts/teardown.sh          # deletes the local cluster
scripts/teardown.sh --repo   # also deletes the GitHub repo (asks first)
```
