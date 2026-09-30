The spec at .scratch/greeting/spec.md and its three tickets in .scratch/greeting/issues/ are final; they've already been through grilling, to-spec and to-tickets.

You have my go-ahead to run implement-spec on them now, using your dispatch loop. This is an unattended test run: don't ask me anything and don't wait for confirmation; make reasonable decisions yourself and note them.

Specifics for this run:
- There's no remote and the tracker is local markdown, so there's no pull request. Finish on the integration branch spec/greeting.
- Skip the optional exploration step.
- Run the single code-review pass at the end as usual, and apply its fixes once.
- Resolve the tickets the way docs/agents/issue-tracker.md says, and clean up the ticket worktrees.
- Don't run retro. Stop when the integration branch is done and report it.
