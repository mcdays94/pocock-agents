# Smoke test for pocock-agents. Works with OrbStack, Docker Desktop or plain Docker.
#
# Build from the repo root:
#   docker build -f test/smoke/Dockerfile -t pocock-smoke .
# Deterministic checks only (no model calls, no key needed):
#   docker run --rm pocock-smoke
# Full run (pocock builds a three-ticket spec; this spends tokens):
#   docker run --rm -e ANTHROPIC_API_KEY pocock-smoke
# Add -e POCOCK_MODEL=<provider/model> to run both agents on another model.
FROM node:22-bookworm

ARG OPENCODE_VERSION=1.18.33
RUN npm install -g "opencode-ai@${OPENCODE_VERSION}"

# Matt's skills, installed the way the README recommends.
RUN DO_NOT_TRACK=1 DISABLE_TELEMETRY=1 npx -y skills@latest add mattpocock/skills -g -a opencode -s '*' -y

# The global rule from the README: built-in subagents may use the worktree root.
RUN mkdir -p /root/.config/opencode \
 && printf '%s\n' '{"$schema":"https://opencode.ai/config.json","permission":{"external_directory":{"/tmp/pocock-workers/*":"allow"}}}' \
    > /root/.config/opencode/opencode.json \
 && git config --global user.name "pocock smoke" \
 && git config --global user.email "smoke@example.com" \
 && git config --global init.defaultBranch main

COPY agents/ /root/.config/opencode/agents/
COPY test/smoke/ /smoke/
RUN chmod +x /smoke/run.sh

WORKDIR /work
ENTRYPOINT ["/smoke/run.sh"]
