#!/usr/bin/env node
// Astro single-pass build. This keeps the `node build.js` entry that
// docs.yml calls; the VitePress multi-batch pipeline it used to drive
// (an out-of-memory workaround) is no longer needed — Astro renders all
// ~4,400 pages in one process, emitting directory-style URLs natively
// (build.format: "directory"), so the clean-URLs post-processing pass is
// gone too.

import { spawnSync } from "node:child_process";

const MAX_OLD_SPACE = process.env.MAX_OLD_SPACE ?? "6144";

const env = {
  ...process.env,
  NODE_OPTIONS: `--max-old-space-size=${MAX_OLD_SPACE}`,
};
const result = spawnSync("npx", ["astro", "build"], {
  stdio: "inherit",
  env,
  shell: process.platform === "win32",
});
process.exit(result.status ?? 1);
