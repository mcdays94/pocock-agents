# 01: Formal register for greetings

**What to build:** `greet(name, { register: "formal" })` returns "Good day, <name>."; without options it still returns "Hello, <name>!". Names are trimmed, and an empty or blank name throws a `RangeError` with the message "a name is required".

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] `greet("Ada", { register: "formal" })` returns "Good day, Ada."
- [ ] `greet("  Ada ")` returns "Hello, Ada!"
- [ ] `greet("  ")` throws a `RangeError` with the message "a name is required"
