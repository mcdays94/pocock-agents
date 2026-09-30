# 03: greet command line

**What to build:** `node bin/greet.js [--formal] [--farewell] <name>` prints the greeting, or the farewell with `--farewell`, in the chosen register: one line, exit status 0. With no name it prints "a name is required" to stderr and exits with status 1.

**Blocked by:** 01, 02

**Status:** ready-for-agent

- [ ] `node bin/greet.js Ada` prints "Hello, Ada!"
- [ ] `node bin/greet.js --formal --farewell Ada` prints "Farewell, Ada."
- [ ] `node bin/greet.js` prints "a name is required" to stderr and exits with status 1
