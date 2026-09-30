// Checks a checkout of spec/greeting against the spec, independently of the
// tests the workers wrote. Usage: node acceptance.mjs <checkout-dir>
// Exit status is the number of failed checks (0 = all passed).
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";
import path from "node:path";

const dir = path.resolve(process.argv[2] ?? ".");
let failed = 0;

async function check(label, fn) {
  try {
    await fn();
    console.log(`PASS  acceptance: ${label}`);
  } catch (error) {
    failed++;
    console.log(`FAIL  acceptance: ${label}: ${error.message.split("\n")[0]}`);
  }
}

const load = (file) => import(pathToFileURL(path.join(dir, file)).href);
const cli = (...args) => spawnSync(process.execPath, [path.join(dir, "bin/greet.js"), ...args], { encoding: "utf8" });

await check("casual greeting unchanged", async () => {
  const { greet } = await load("src/greeting.js");
  assert.equal(greet("Ada"), "Hello, Ada!");
});
await check("formal greeting", async () => {
  const { greet } = await load("src/greeting.js");
  assert.equal(greet("Ada", { register: "formal" }), "Good day, Ada.");
});
await check("greeting trims the name", async () => {
  const { greet } = await load("src/greeting.js");
  assert.equal(greet("  Ada "), "Hello, Ada!");
});
await check("blank name is a RangeError", async () => {
  const { greet } = await load("src/greeting.js");
  assert.throws(() => greet("  "), { name: "RangeError", message: "a name is required" });
});
await check("casual farewell", async () => {
  const { farewell } = await load("src/farewell.js");
  assert.equal(farewell("Ada"), "Goodbye, Ada!");
});
await check("formal farewell", async () => {
  const { farewell } = await load("src/farewell.js");
  assert.equal(farewell("Ada", { register: "formal" }), "Farewell, Ada.");
});
await check("command line greets", () => {
  const run = cli("Ada");
  assert.equal(run.status, 0);
  assert.equal(run.stdout.trim(), "Hello, Ada!");
});
await check("command line: formal farewell", () => {
  const run = cli("--formal", "--farewell", "Ada");
  assert.equal(run.status, 0);
  assert.equal(run.stdout.trim(), "Farewell, Ada.");
});
await check("command line without a name fails", () => {
  const run = cli();
  assert.equal(run.status, 1);
  assert.match(run.stderr, /a name is required/);
});

process.exit(failed);
