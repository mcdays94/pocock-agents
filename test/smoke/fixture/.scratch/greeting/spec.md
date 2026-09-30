# Spec: registers, farewells and a greet command

## Problem Statement

Greeter can only say a casual hello, from code. Script authors want a formal register and a farewell, and people at a shell want to use it without writing JavaScript.

## Solution

Greetings and farewells both come in two registers, casual (the default) and formal. A `greet` command line prints either one for a name.

## User Stories

1. As a script author, I want `greet("Ada")` to keep returning "Hello, Ada!", so that existing callers don't break.
2. As a script author, I want `greet("Ada", { register: "formal" })` to return "Good day, Ada.", so that I can greet formally.
3. As a script author, I want `farewell("Ada")` to return "Goodbye, Ada!", so that I can say goodbye.
4. As a script author, I want `farewell("Ada", { register: "formal" })` to return "Farewell, Ada.", so that I can say goodbye formally.
5. As a script author, I want names trimmed, so that "  Ada " is greeted as "Ada".
6. As a script author, I want an empty or blank name to throw a `RangeError` with the message "a name is required", so that mistakes fail loudly.
7. As a shell user, I want `node bin/greet.js Ada` to print "Hello, Ada!", so that I can greet from a terminal.
8. As a shell user, I want `--formal` to switch the register and `--farewell` to say goodbye instead, in any combination.
9. As a shell user, I want a missing name to print "a name is required" to stderr and exit with status 1.

## Implementation Decisions

- The greeting module keeps its `greet(name, options)` export and gains an optional `options.register` of `"casual"` or `"formal"`, defaulting to casual.
- A new farewell module exports `farewell(name, options)` with the same options, the same trimming and the same empty-name rule.
- The command line is a small script over both modules. It prints exactly one line and exits 0 on success.
- Module layout, fixed so that parallel tickets agree: `src/greeting.js`, `src/farewell.js`, `bin/greet.js`. Everything is an ES module.

## Testing Decisions

- Test only at these seams: the exported `greet` and `farewell` functions, and the command line run as a child process (`node bin/greet.js ...`), asserting stdout, stderr and exit status.
- Good tests check behaviour through those seams only, never module internals.
- Use `node:test` and `node:assert/strict`, like the existing `test/greeting.test.js`. No dependencies.

## Out of Scope

Localisation, more registers, configuration files, and publishing the command to npm.

## Further Notes

None.
