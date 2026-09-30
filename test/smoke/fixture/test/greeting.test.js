import { test } from "node:test";
import assert from "node:assert/strict";
import { greet } from "../src/greeting.js";

test("greets someone by name", () => {
  assert.equal(greet("Ada"), "Hello, Ada!");
});
