# Recording the end-to-end run

A real run takes about 15 to 20 minutes. Speed up the waiting parts in editing and the video lands around 6 to 8 minutes.

## Before you press record

1. Run `./setup.sh` and wait for the first Release workflow to finish (check with `gh run list`).
2. Do a full practice run once with a second story, so nothing surprises you on camera.
3. Close notifications. Use a clean browser profile. Set the terminal font to 18 pt or larger.
4. Open these and arrange them (two screens help):

| Window | Command or URL |
|---|---|
| Jira board | `https://<your-site>.atlassian.net/browse/PROJ-1` |
| GitHub Actions | `https://github.com/<you>/ai-delivery-demo/actions` |
| Terminal 1, canary view | `kubectl argo rollouts get rollout reports -n reports --watch` |
| Terminal 2, Argo CD | `kubectl -n argocd port-forward svc/argocd-server 8080:443`, then open https://localhost:8080 |
| Terminal 3, the app | `kubectl -n reports port-forward svc/reports-stable 8081:80`, then open http://localhost:8081 |

**OBS (free):** 1920×1080, 30 fps, MKV (remux to MP4 after), CRF/quality around 20. Add a webcam corner if you like.

## Shot list

| # | Show | Real time | Say (suggested) |
|---|---|---|---|
| 1 | The app at localhost:8081: no export button | 0:20 | "This is our sales report. There's no way to export it yet." |
| 2 | The Jira story PROJ-1 and its acceptance criteria | 0:30 | "Here's the story. Clear goal, clear acceptance criteria, files named." |
| 3 | Add the label `ai-ready` | 0:10 | "This is the only thing I'll do. One label." |
| 4 | Actions: the Agent run starts, open its log | 3 to 8 min (speed up) | "Jira just started an AI agent in a fresh sandbox. It reads the story, writes tests first, then the code, and runs the tests until they pass." |
| 5 | The pull request: diff, labels `ai-authored` and `risk:low` | 0:40 | "It opened a pull request on its own. The risk policy scored it low, so it can merge itself, but only if CI passes." |
| 6 | CI checks turning green, then "merged" | 1 to 2 min (speed up) | "Typecheck, tests, build. All green. Auto-merge kicks in." |
| 7 | Release run: build, sign, push, bump gitops | 2 to 3 min (speed up) | "Every merge becomes a signed image, and the new version is written to Git." |
| 8 | Argo CD UI: app goes OutOfSync, then Syncing | 0:30 | "Argo CD sees the change in Git and starts the rollout." |
| 9 | Terminal 1: canary 25%, smoke test, 50%, 75%, 100% | 2 to 3 min (speed up) | "A quarter of the pods first. A smoke test checks the new version. Then half, three quarters, all of it. If the test failed, it would roll back by itself." |
| 10 | Back to the app: refresh, click Export CSV, open the file | 0:40 | "And there it is, live. Nobody wrote a line of this code." |
| 11 | Jira: the agent's comment with the PR link | 0:20 | "Jira has the full trail: the run, the pull request, the result." |
| 12 | Close: one human touch, humans approve risky changes | 0:20 | "One human touch. Anything risky still waits for a person. That's AI-driven delivery with a human in the loop." |

## Show the human-in-the-loop path too (optional, +2 minutes)

Create a second story that asks for a change in `package.json` (for example "Add a lint script").
The risk policy scores it **high**, comments that a human must review, and does not auto-merge.
That 30-second moment shows viewers the guardrail works.

## If something goes wrong on camera

- Agent run failed: open the log, show the Jira comment, then re-run with `scripts/trigger.sh PROJ-1`. Failure plus recovery is good content.
- Stuck waiting: cut, and resume when the next step starts.
- Canary paused at 25% for a failed smoke test: show it. That is the rollback safety net working.
