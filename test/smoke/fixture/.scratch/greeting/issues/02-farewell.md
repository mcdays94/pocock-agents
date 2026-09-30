# 02: Farewell

**What to build:** a farewell module: `farewell(name)` returns "Goodbye, <name>!" and `farewell(name, { register: "formal" })` returns "Farewell, <name>.". Same trimming and empty-name rule as greetings.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] `farewell("Ada")` returns "Goodbye, Ada!"
- [ ] `farewell("Ada", { register: "formal" })` returns "Farewell, Ada."
- [ ] `farewell("")` throws a `RangeError` with the message "a name is required"
