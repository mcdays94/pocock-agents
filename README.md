# pocock-agents

Two [OpenCode](https://opencode.ai/) agents that run [Matt Pocock](https://www.aihero.dev/)'s skill-driven engineering flow end to end: grill an idea until it's sharp, turn it into a spec and tickets, build the tickets test-first with parallel workers in isolated git worktrees, review the result, and look back with a retro.

Blog post with the original rationale: **[How I cloned Matt Pocock into OpenCode Agents](https://mdias.info/posts/cloning-matt-pocock-opencode/)**. The flow has changed twice since then; this README is current.

> **2026-10 update.** Re-synced with [`mattpocock/skills`](https://github.com/mattpocock/skills) v1.3 (`main` at `d81f3a1`, 2026-09-29). Since the May sync Matt shipped v1.0 to v1.3: `to-prd` became `to-spec`, `to-issues` became `to-tickets`, `diagnose` became `diagnosing-bugs`, a dozen skills were removed, `CONTEXT.md` became `GLOSSARY.md`, and `implement-spec` now does the parallel build these agents used to improvise. This update also fixes a bug that predates it: under OpenCode's last-match-wins permission rule the worker couldn't load any skill, `tdd` included. See [CHANGELOG.md](./CHANGELOG.md) for the details and upgrade steps.

## The agents

| File | Role |
| --- | --- |
| [`agents/pocock.md`](./agents/pocock.md) | **Orchestrator** (primary agent). Routes with Matt's `ask-matt`, walks the flow phase by phase, asks before each step Matt meant a person to start, and runs `implement-spec` with OpenCode worktrees and parallel workers. |
| [`agents/pocock-worker.md`](./agents/pocock-worker.md) | **Implementer** (subagent). Takes one ticket and a prepared worktree, builds it with `tdd` at the seams the spec agreed, merges the integration branch tip into its branch, and reports back. Never pushes. |

Matt's skills hold the discipline; these agents only supply what the skills expect from the tool they run in. `implement-spec` assumes every implementer gets its own git worktree, and OpenCode's task tool doesn't do that, so pocock creates the worktrees, runs the merges, and gives the worker permissions that keep it inside its worktree.

## Prerequisites

1. **OpenCode.** Tested with v1.18.33.
2. **Matt's skills, installed for OpenCode:**

   ```bash
   npx skills@latest add mattpocock/skills -a opencode
   ```

   Add `-g` to install for your user rather than the current project. Global installs land in `~/.agents/skills/`, project installs in `.agents/skills/`, and OpenCode reads both. Take at least the engineering and productivity skills, and make sure `setup-matt-pocock-skills` is among them.

   Matt's Claude Code plugin (`claude plugins install mattpocock-skills`) won't help here: OpenCode doesn't read Claude Code plugins. If you'd rather track Matt's repo directly, clone it and symlink the folders under `skills/engineering/` and `skills/productivity/` into `~/.config/opencode/skills/`.

3. **One global permission rule (recommended).** Both agents may work in `/tmp/pocock-workers`, where the worktrees live. The built-in subagents pocock starts (`general` for exploration notes) don't inherit that, so without this rule OpenCode asks you before they touch the worktree root. Add it to `~/.config/opencode/opencode.json`:

   ```json
   {
     "$schema": "https://opencode.ai/config.json",
     "permission": {
       "external_directory": {
         "/tmp/pocock-workers/*": "allow",
         "/private/tmp/pocock-workers/*": "allow"
       }
     }
   }
   ```

   The second line is for macOS, where `/tmp` resolves to `/private/tmp`.

## Installation

```bash
mkdir -p ~/.config/opencode/agents
curl -o ~/.config/opencode/agents/pocock.md https://raw.githubusercontent.com/mcdays94/pocock-agents/main/agents/pocock.md
curl -o ~/.config/opencode/agents/pocock-worker.md https://raw.githubusercontent.com/mcdays94/pocock-agents/main/agents/pocock-worker.md
```

Or clone this repo and symlink the two files into `~/.config/opencode/agents/`.

Check the install without spending tokens, from inside any git repo:

```bash
opencode debug agent pocock-worker --tool skill --params '{"name":"tdd"}'      # prints the tdd skill
opencode debug agent pocock-worker --tool skill --params '{"name":"to-spec"}'  # refused
```

## Per-repo setup

Run `/setup-matt-pocock-skills` once per repo, or let pocock offer it the first time a step needs the issue tracker. It records:

- **Issue tracker**: GitHub (`gh`), GitLab (`glab`), local markdown (`.scratch/<feature>/spec.md` plus one file per ticket under `.scratch/<feature>/issues/`), or a workflow you describe.
- **Triage labels**: the five canonical roles, asked about only when `triage` is installed.
- **Domain docs**: `GLOSSARY.md` and `docs/adr/` at the root, or `GLOSSARY-MAP.md` for monorepos.

It writes `docs/agents/*.md` and an `## Agent skills` block into `CLAUDE.md` if that file exists, otherwise `AGENTS.md`. OpenCode loads only the first of `AGENTS.md` and `CLAUDE.md` it finds, so in a repo that has both, move the block into `AGENTS.md`.

Coming from an older setup? Rename the glossary (`git mv CONTEXT.md GLOSSARY.md`, and `CONTEXT-MAP.md` likewise): Matt's skills only look for the new name.

## Usage

Start OpenCode with pocock selected (or press Tab to switch to it) and describe what you want:

```bash
opencode --agent pocock
> I want to build X
```

The main flow, which follows Matt's `ask-matt`:

1. **Grill.** pocock loads `grilling` and `domain-modeling` and interviews you in numbered rounds, each question with a recommended answer. Terms land in `GLOSSARY.md` and hard-to-reverse decisions in `docs/adr/` as they're settled.
2. **Prototype** (optional), when a question needs running code to settle it.
3. **Spec.** `to-spec` writes the spec from the conversation and confirms the test seams with you.
4. **Tickets.** `to-tickets` splits the spec into tracer-bullet tickets, each declaring which tickets block it.
5. **Build.** `implement` for a single ticket, or `implement-spec` for the whole spec. For `implement-spec`, pocock creates an integration branch (`spec/<slug>`) and one worktree per ready ticket under `/tmp/pocock-workers/`, runs a `pocock-worker` in each (in parallel), fast-forwards finished tickets into the integration branch, and starts tickets as their blockers land.
6. **Review.** One `code-review` pass over the integration branch, one round of fixes, then a draft PR if your tracker closes work through PRs.
7. **Retro.** `retro` suggests changes to the environment (checks, standards, pointers) based on what went wrong.

Before each step that Matt's skills expect a person to start (`to-spec`, `to-tickets`, `implement-spec`, `retro`, ...), pocock proposes it and waits for your yes. OpenCode doesn't enforce that split itself. In OpenCode v1 every skill is also a slash command, so you can run any step by hand (`/to-spec`), with or without pocock.

Other entry points (incoming bug reports with `triage`, hard bugs with `diagnosing-bugs`, foggy multi-session efforts with `wayfinder`, codebase health with `improve-codebase-architecture`) are mapped in [`agents/pocock.md`](./agents/pocock.md).

**Parallelism.** OpenCode v1 runs subagents in the background only with `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`. With it, pocock starts each ticket the moment its last blocker merges; without it, workers run in batches and pocock recomputes the ready set after each batch.

**PR per ticket.** Ask for it and pocock branches every ticket from the default branch instead, opens one PR per ticket, and waits for blockers' PRs to merge before starting the tickets they block. Workers still never push; pocock does.

## Customization

The agents are plain markdown; edit anything that doesn't fit.

- **Stack skills.** The table at the end of `pocock.md` loads skills when it sees their signals. The defaults are for Cloudflare Workers, React Flow and Playwright projects; swap in your own and keep the worker's `skill:` allow-list in step.
- **Model.** Both agents pin a model in their `model:` frontmatter. Change it, or delete the line to use your OpenCode default.
- **Permissions.** OpenCode applies the **last** matching rule, so keep `"*"` first and exceptions after it. Patterns match each command's full text, which is why the worker denies both `git push*` and `git -C * push*`.
- **Worktree root.** `/tmp/pocock-workers`. If you move it, update the `external_directory` rules in both agents and in your global config.
- **task-observer.** If you have a `task-observer` skill installed, pocock loads it at session start; otherwise it skips that step.

## Keeping up with upstream

Matt's skills move fast: the May version of these agents was broken by June. [`scripts/check-skills.sh`](./scripts/check-skills.sh) clones `mattpocock/skills` and fails if either agent names a skill that upstream has renamed or removed, or if the worker is allowed a skill that needs a person. [A GitHub Action](./.github/workflows/check-skills.yml) runs it weekly and on every change to the agents.

```bash
scripts/check-skills.sh                  # clones upstream into a temp dir
scripts/check-skills.sh ~/src/mp-skills  # or uses an existing clone
```

## Testing

[`test/smoke/`](./test/smoke/) is a Docker smoke test; it runs the same under OrbStack, Docker Desktop or plain Docker. It installs OpenCode, Matt's skills and these agents into a container, then runs the checks against a tiny fixture project that already has a spec and three tickets (two independent, one blocked by both) on a local-markdown tracker.

```bash
docker build -f test/smoke/Dockerfile -t pocock-smoke .
docker run --rm pocock-smoke                         # deterministic checks, no model calls
docker run --rm -e ANTHROPIC_API_KEY pocock-smoke    # full run: pocock builds the spec (spends tokens)
```

The deterministic checks confirm that both agents load, that each can load the skills it needs and is refused the rest, and that the worker's git and `gh` denies hold. The full run has pocock carry out `implement-spec`. It then checks the integration branch, the worktree cleanup and the ticket statuses, and runs an acceptance script written against the spec, independent of the tests the workers wrote. Add `-e POCOCK_MODEL=<provider/model>` to run both agents on a different model.

## Credits

All the engineering discipline is in [Matt Pocock's skills](https://github.com/mattpocock/skills); their docs live at [aihero.dev/skills](https://www.aihero.dev/skills). These agents only wire them into OpenCode with an orchestrator/worker pattern and git worktree isolation.

## License

MIT
