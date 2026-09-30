# Changelog

## 2026-10: re-sync with mattpocock/skills v1.3

Tracks [`mattpocock/skills`](https://github.com/mattpocock/skills) `main` at `d81f3a1` (2026-09-29), which carries the v1.3 changes. Since the May sync, upstream shipped v1.0 (Jun 17), v1.1 (Jul 8), v1.2 (Aug 5) and v1.2.3 (Aug 6).

### Fixed

- **The worker couldn't load any skill.** OpenCode applies the last matching permission rule, and the worker's `skill:` block ended with `"*": deny`, so `opencode debug agent pocock-worker --tool skill` reported the skill tool as disabled. The worker got its TDD guidance only from its own prompt. The catch-all now comes first.
- **Force pushes got through.** OpenCode matches bash patterns literally against each command's full text, so `git push --force*` didn't catch `git push -f`, `git push origin x --force` or `git push origin +x`. The worker now can't push at all.
- **Worktrees needed approval for every file.** The worktrees live outside the project, and OpenCode asks before touching external directories. Both agents now allow `/tmp/pocock-workers` (and macOS's `/private/tmp/pocock-workers`).

### Changed

- **The orchestrator points at skills instead of restating them.** The old `pocock.md` described each skill's internals, and every description went stale when Matt changed the skill. It now loads `ask-matt` as its routing map and keeps only what OpenCode has to supply: worktrees, subagent dispatch and the merge loop.
- **User-invoked skills wait for a yes.** Matt marks skills a person should start (`to-spec`, `to-tickets`, `implement-spec`, `retro`, ...) with `disable-model-invocation: true`. OpenCode ignores that flag, so pocock proposes those steps and waits.
- **Grilling loads `grilling` and `domain-modeling` directly.** `grill-with-docs` is now a wrapper around them, and Matt's docs report that wrappers don't reliably load what they name.
- **Parallel build follows `implement-spec`.** Tickets used to run in waves off `origin/main`, each opening its own PR, and a wave waited for the previous wave's PRs to merge. Now:
  - one integration branch (`spec/<slug>`) lives in its own worktree;
  - ticket worktrees (`ticket/<slug>/<id>`) branch from its tip;
  - pocock computes the frontier from its own merge record, because GitHub's blocked-by count only drops when a blocker closes;
  - finished tickets fast-forward into the integration branch;
  - when a fast-forward fails because another ticket landed first, pocock resumes that worker to merge the new tip;
  - one `code-review` pass runs at the end, then one round of fixes, then a draft PR only if the tracker closes work through PRs.

  PR-per-ticket is still available on request.
- **The worker is `implement-spec`'s implementer.**
  - It installs dependencies in its worktree and takes `tdd`'s pre-agreed seams from the spec's Testing Decisions.
  - It merges the integration tip into its branch before reporting, and reports evidence the PR body can quote.
  - It never pushes, stashes (`refs/stash` is shared by every worktree), runs `git worktree`, opens PRs or closes issues.
  - It now also flags tests that silently skip because a worktree lacks gitignored files.
- **Glossary.** `GLOSSARY.md` (and `GLOSSARY-MAP.md`) replace `CONTEXT.md`. The agents still read `CONTEXT.md` and `UBIQUITOUS_LANGUAGE.md` in older repos.
- **`task-observer` is optional.** It loads only if it's installed.
- **`prd-to-plan` is gone.** `to-tickets` with a local-markdown tracker covers solo plans.
- **New:** `scripts/check-skills.sh` and a weekly GitHub Action that fail when upstream renames or removes a skill the agents use; `test/smoke/`, a Docker smoke test.

### Upgrading

1. Reinstall Matt's skills (`npx skills@latest add mattpocock/skills -a opencode`) and remove the old folders: `to-prd`, `to-issues`, `diagnose`, `zoom-out`, `caveman`, `write-a-skill`, `edit-article`, `obsidian-vault`, and the deprecated ones if you still have them.
2. Re-download both agent files.
3. Add the global `external_directory` rule from the README.
4. In each repo: `git mv CONTEXT.md GLOSSARY.md` (and `CONTEXT-MAP.md` likewise), and re-run `/setup-matt-pocock-skills` to refresh `docs/agents/*.md`. The local-markdown layout changed to `.scratch/<feature>/spec.md` plus `.scratch/<feature>/issues/<NN>-<slug>.md`, and the triage label file is now optional.
5. Branch names changed: `spec/<slug>` for the integration branch and `ticket/<slug>/<id>` per ticket, instead of `issue/<N>-<slug>`.

### Skill names, May to October

| May name | Now | Since |
| --- | --- | --- |
| `to-prd` | `to-spec` | v1.1 |
| `to-issues`, `prd-to-plan` | `to-tickets` | v1.1 |
| `diagnose` | `diagnosing-bugs` | v1.0 |
| `write-a-skill` | `writing-for-agents` (via `writing-great-skills`) | v1.0, v1.2 |
| `grill-with-docs`, `grill-me` | wrappers around `grilling` (+ `domain-modeling`) | v1.0 |
| `zoom-out`, `caveman` | removed | v1.0 |
| `edit-article`, `obsidian-vault` | removed | v1.2 |
| `ubiquitous-language`, `design-an-interface`, `qa`, `request-refactor-plan` | removed; see `domain-modeling`, `codebase-design`, `triage`, `to-spec` | v1.2 |
| `CONTEXT.md` / `CONTEXT-MAP.md` | `GLOSSARY.md` / `GLOSSARY-MAP.md` | v1.3 |

New skills pocock uses: `ask-matt`, `implement`, `implement-spec`, `code-review`, `pr`, `retro`, `wayfinder`, `research`, `wizard`, `codebase-design`, `domain-modeling`, `grilling`, `to-questionnaire`.

## 2026-05: realigned with the April/May refactor

Matt refactored `mattpocock/skills` between 2026-04-28 and 2026-05-07.

- **Renamed:** `prd-to-issues` → `to-issues`, `write-a-prd` → `to-prd` (it stopped interviewing), and `github-triage` → `triage`.
- **Deprecated:** `triage-issue` and `qa` (into `triage`), `design-an-interface` (into `prototype`), `ubiquitous-language` (into `grill-with-docs`) and `request-refactor-plan`.
- **Added:** `diagnose`, `prototype`, `grill-with-docs`, `zoom-out`, `handoff`, `caveman` and `setup-matt-pocock-skills`.
- **Conventions:** `UBIQUITOUS_LANGUAGE.md` became `CONTEXT.md` plus `docs/adr/`, and issue trackers became configurable (GitHub, GitLab or local markdown).

## 2026-04: initial release

`pocock` and `pocock-worker`: grill, PRD, issues, and parallel TDD workers on git worktrees.
