#!/usr/bin/env bash
# pocock-agents smoke test. Runs inside the image built from test/smoke/Dockerfile.
#
#   1. Always: deterministic checks that make no model calls. Agents load, each
#      one can load the skills it needs and is refused the ones it mustn't, and
#      the worker's git/gh denies hold.
#   2. Only when ANTHROPIC_API_KEY is set: pocock runs implement-spec on a
#      three-ticket spec (two independent tickets, one blocked by both), then an
#      independent acceptance script checks the result against the spec.
#
# POCOCK_MODEL=<provider/model> overrides the model: line of both agents.
set -uo pipefail

smoke="${SMOKE_DIR:-/smoke}"
work="${WORK_DIR:-/work}"
agents="${OPENCODE_AGENTS_DIR:-$HOME/.config/opencode/agents}"
failures=0

pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; failures=$((failures + 1)); }
check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}
# Capture first, then grep: `cmd | grep -q` under pipefail fails when grep exits
# early and the writer gets SIGPIPE.
loads() {
  local out
  out="$(opencode debug agent "$1" --tool skill --params "{\"name\":\"$2\"}" 2>&1)"
  grep -q "Loaded skill: $2" <<< "$out"
}
refused() {
  local out
  out="$(opencode debug agent "$1" --tool "$2" --params "$3" 2>&1)"
  grep -q "prevents you from using" <<< "$out"
}
bash_params() { printf '{"command":"%s","description":"smoke"}' "$1"; }

if [ -n "${POCOCK_MODEL:-}" ]; then
  sed -i "s#^model: .*#model: ${POCOCK_MODEL}#" "$agents/pocock.md" "$agents/pocock-worker.md"
fi
# A headless run can't answer the question tool; the prompt tells pocock not to ask.
sed -i 's/^  question: allow$/  question: deny/' "$agents/pocock.md"

repo="$work/greeter"
rm -rf "$repo" /tmp/pocock-workers/greeter
mkdir -p "$work"
cp -R "$smoke/fixture" "$repo"
cd "$repo" || exit 1
mv gitignore .gitignore
git init -q -b main
git add -A
git commit -qm "greeter: base"
base="$(git rev-parse HEAD)"

echo "== deterministic checks (no model calls)"
check "opencode lists pocock as a primary agent" sh -c 'opencode agent list 2>/dev/null | grep -q "^pocock (primary)"'
check "opencode lists pocock-worker as a subagent" sh -c 'opencode agent list 2>/dev/null | grep -q "^pocock-worker (subagent)"'
check "the fixture keeps its spec untracked, like a real .scratch/" sh -c '! git ls-files --error-unmatch .scratch/greeting/spec.md'
for skill in ask-matt grilling domain-modeling to-spec to-tickets implement-spec code-review pr retro; do
  check "pocock can load $skill" loads pocock "$skill"
done
for skill in tdd codebase-design diagnosing-bugs; do
  check "pocock-worker can load $skill" loads pocock-worker "$skill"
done
for skill in to-spec grill-with-docs code-review implement-spec triage; do
  check "pocock-worker is refused $skill" refused pocock-worker skill "{\"name\":\"$skill\"}"
done
for cmd in "git push origin main" "git -C . push origin main" "git stash" "git worktree list" "git reset --hard HEAD" "gh pr create --fill"; do
  check "pocock-worker is refused: $cmd" refused pocock-worker bash "$(bash_params "$cmd")"
done
check "fixture tests pass on main" npm test --silent

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "SKIP  full run: set ANTHROPIC_API_KEY to let pocock build the spec"
  echo "== $failures failure(s)"
  exit $((failures > 0))
fi

echo "== full run: pocock runs implement-spec (this calls the model)"
opencode run --agent pocock --auto --title pocock-smoke "$(cat "$smoke/prompt.md")" 2>&1 | tee "$work/transcript.txt"

check "integration branch spec/greeting exists" git rev-parse -q --verify spec/greeting
check "main is untouched" test "$(git rev-parse main)" = "$base"
check "the main checkout is still on main" test "$(git rev-parse --abbrev-ref HEAD)" = main
check "ticket worktrees were cleaned up" sh -c '! ls -d /tmp/pocock-workers/greeter/*/tickets/*/ >/dev/null 2>&1'
check "every ticket is marked done" sh -c 'for f in .scratch/greeting/issues/*.md; do grep -qi "status:\**[[:space:]]*done" "$f" || exit 1; done'

verify=/tmp/smoke-verify
rm -rf "$verify"
git worktree prune
if git worktree add -q --detach "$verify" spec/greeting 2>/dev/null; then
  check "the project's own tests pass on spec/greeting" sh -c "cd '$verify' && npm test --silent"
  node "$smoke/acceptance.mjs" "$verify"
  failures=$((failures + $?))
  git worktree remove --force "$verify"
else
  fail "could not check out spec/greeting for acceptance checks"
fi

echo "== transcript: $work/transcript.txt"
echo "== $failures failure(s)"
exit $((failures > 0))
