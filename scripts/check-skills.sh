#!/usr/bin/env bash
# Checks the agents against mattpocock/skills and fails when they drift.
#
#   scripts/check-skills.sh [path-to-a-mattpocock-skills-clone]
#
# Without a path it clones https://github.com/mattpocock/skills into a temp dir.
# UPSTREAM_REF picks the upstream ref to check against (default: the clone's
# default branch). AGENTS_DIR points at the agent files (default: agents/).
#
# It fails when:
#   1. an agent names a skill that existed upstream but no longer does
#      (renamed or removed), or
#   2. the worker's permission block allows a user-invoked skill
#      (disable-model-invocation: true). Those need a person; the worker
#      runs unattended.
# Names that never existed upstream (stack skills, labels, commands) are ignored.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
agents_dir="${AGENTS_DIR:-$root/agents}"
upstream="${1:-}"

if [ -z "$upstream" ]; then
  upstream="$(mktemp -d)/skills"
  git clone --quiet https://github.com/mattpocock/skills "$upstream"
fi
ref="${UPSTREAM_REF:-HEAD}"
git -C "$upstream" rev-parse --verify --quiet "$ref^{commit}" >/dev/null || {
  echo "error: $ref is not a commit in $upstream" >&2
  exit 2
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Skill names = the folder holding each SKILL.md, whatever bucket layout was in use.
skill_names() { grep -E '(^|/)SKILL\.md$' | sed -E 's#/?SKILL\.md$##; s#.*/##' | sort -u; }

git -C "$upstream" ls-tree -r --name-only "$ref" | skill_names > "$work/current"
git -C "$upstream" log --name-only --format= "$ref" | skill_names > "$work/ever"
comm -23 "$work/ever" "$work/current" > "$work/gone"

# Current skills a person has to start.
: > "$work/user-invoked"
while read -r path; do
  frontmatter="$(git -C "$upstream" show "$ref:$path" | awk 'NR == 1 && /^---$/ { f = 1; next } f && /^---$/ { exit } f')"
  if grep -q '^disable-model-invocation: *true' <<< "$frontmatter"; then
    echo "$path" | skill_names >> "$work/user-invoked"
  fi
done < <(git -C "$upstream" ls-tree -r --name-only "$ref" | grep -E '(^|/)SKILL\.md$')
sort -u -o "$work/user-invoked" "$work/user-invoked"

# Names the agents mention: `backticked` or "quoted" kebab-case tokens.
grep -ohE '`[a-z][a-z0-9-]*`|"[a-z][a-z0-9-]*"' "$agents_dir"/*.md | tr -d '`"' | sort -u > "$work/referenced"

# Skills the worker's permission block allows.
awk '
  /^  skill:/ { in_skill = 1; next }
  in_skill && /^  [^ ]/ { in_skill = 0 }
  in_skill && /: *allow/ { gsub(/[" ]/, ""); sub(/:allow.*/, ""); print }
' "$agents_dir/pocock-worker.md" | sort -u > "$work/worker-allows"

status=0
upstream_desc="$(git -C "$upstream" log -1 --format='%h %cs' "$ref")"
echo "mattpocock/skills at $upstream_desc: $(wc -l < "$work/current" | tr -d ' ') skills, $(wc -l < "$work/gone" | tr -d ' ') renamed or removed over its history"

stale="$(comm -12 "$work/referenced" "$work/gone")"
if [ -n "$stale" ]; then
  status=1
  echo "FAIL  agents name skills that no longer exist upstream:"
  while read -r name; do
    printf '        %s  (%s)\n' "$name" "$(grep -lE "[\`\"]$name[\`\"]" "$agents_dir"/*.md | xargs -n1 basename | tr '\n' ' ' | sed 's/ $//')"
  done <<< "$stale"
else
  echo "PASS  every upstream skill the agents name still exists"
fi

bad_allow="$(comm -12 "$work/worker-allows" "$work/user-invoked")"
if [ -n "$bad_allow" ]; then
  status=1
  echo "FAIL  pocock-worker allows user-invoked skills (they need a person):"
  sed 's/^/        /' <<< "$bad_allow"
else
  echo "PASS  pocock-worker allows no user-invoked skills"
fi

exit "$status"
