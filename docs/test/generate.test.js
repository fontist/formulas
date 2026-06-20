#!/usr/bin/env node
// Smoke test for docs/generate.js output.
// Run after `node generate.js` — validates the generated browse/*.md pages
// have the expected structure and component props.
//
// Usage: node --test docs/test/generate.test.js
//    or: cd docs && npm test

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const browseDir = resolve(__dirname, "..", "browse");

async function readPage(slug) {
  const path = resolve(browseDir, `${slug}.md`);
  if (!existsSync(path)) return null;
  return readFile(path, "utf8");
}

describe("generate.js output structure", () => {
  it("inter.md exists and has FontSpecimen with live specimen props", async () => {
    const md = await readPage("inter");
    assert.ok(md, "inter.md should exist");

    assert.match(
      md,
      /<FontSpecimen\s+slug="inter"[^>]*:redistributable="true"[^>]*woff2-path="fonts\/inter\.woff2"/,
      'FontSpecimen should have :redistributable="true" (boolean) and woff2-path for OFL fonts'
    );

    assert.match(
      md,
      /<UnicodeCoverage\s+slug="inter"[^>]*:redistributable="true"/,
      'UnicodeCoverage should have :redistributable="true" (boolean binding, not string)'
    );
  });

  it("aptos.md has FontSpecimen WITHOUT woff2-path (proprietary)", async () => {
    const md = await readPage("aptos");
    assert.ok(md, "aptos.md should exist");

    const fsMatch = md.match(/<FontSpecimen\s+slug="aptos"[^>]*>/);
    assert.ok(fsMatch, "FontSpecimen component should be present");

    assert.match(
      fsMatch[0],
      /:redistributable="false"/,
      "should have :redistributable as boolean false"
    );

    assert.doesNotMatch(
      fsMatch[0],
      /woff2-path/,
      "proprietary fonts should NOT have woff2-path"
    );
  });

  it("generate.js source uses :redistributable boolean binding (not string)", async () => {
    const src = await readFile(resolve(__dirname, "..", "generate.js"), "utf8");
    assert.match(
      src,
      /:redistributable="\$\{isRedistributable\}"/,
      "generate.js should emit :redistributable (v-bind boolean) in FontSpecimen and UnicodeCoverage"
    );
    assert.doesNotMatch(
      src,
      /<FontSpecimen[^>]*\sredistributable="/,
      "generate.js should NOT use bare redistributable= (string) in FontSpecimen"
    );
  });

  it("pages have ShaCopy component at the end", async () => {
    const md = await readPage("inter");
    assert.ok(md, "inter.md should exist");
    assert.match(md, /<ShaCopy\s*\/>/, "ShaCopy component should be present");
  });

  it("Unicode Coverage section heading exists", async () => {
    const md = await readPage("inter");
    assert.match(md, /## Unicode Coverage/, "should have Unicode Coverage section");
  });
});

describe("generate.js data outputs", () => {
  it("formulas-data.json exists", async () => {
    const path = resolve(__dirname, "..", "public", "formulas-data.json");
    assert.ok(existsSync(path), "public/formulas-data.json should exist after generate.js");
  });

  it("stats.json exists", async () => {
    const path = resolve(__dirname, "..", "public", "stats.json");
    assert.ok(existsSync(path), "public/stats.json should exist after generate.js");
  });
});
