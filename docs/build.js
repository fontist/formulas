#!/usr/bin/env node
// Multi-pass VitePress build for the formula site.
//
// VitePress runs out of memory when rendering all ~4,300 generated formula
// pages in a single pass, so we render them in batches. The pipeline:
//   1. node generate.js           -> writes browse/<slug>.md, licenses/*.md, public/*.json
//   2. stage browse pages         -> move them out of the source tree
//   3. vitepress build (pass 0)   -> renders the main site (guide, licenses, browse/index)
//   4. for each batch of N pages:
//        - move the batch back into browse/
//        - vitepress build        -> renders just this batch
//        - merge browse/ output into the final dist
//        - move the batch back to staging
//   5. promote the final dist
import { mkdir, rm, readdir, rename, cp, access } from "node:fs/promises";
import { join, dirname, relative } from "node:path";
import { spawnSync } from "node:child_process";

const BROWSE_DIR = "browse";
const STAGING_DIR = ".browse-staging";
const DIST_DIR = ".vitepress/dist";
const FINAL_DIR = ".vitepress/dist-final";

const MAX_OLD_SPACE = process.env.MAX_OLD_SPACE ?? "6144";
const BATCH_SIZE = Number.parseInt(process.env.BATCH_SIZE ?? "500", 10);

async function pathExists(p) {
  try { await access(p); return true; } catch { return false; }
}

async function findMarkdownFiles(dir) {
  const out = [];
  async function walk(d) {
    const entries = await readdir(d, { withFileTypes: true });
    for (const e of entries) {
      const full = join(d, e.name);
      if (e.isDirectory()) await walk(full);
      else if (e.isFile() && e.name.endsWith(".md")) out.push(full);
    }
  }
  await walk(dir);
  return out;
}

async function countHtmlFiles(dir) {
  let n = 0;
  async function walk(d) {
    const entries = await readdir(d, { withFileTypes: true });
    for (const e of entries) {
      const full = join(d, e.name);
      if (e.isDirectory()) await walk(full);
      else if (e.isFile() && e.name.endsWith(".html")) n++;
    }
  }
  await walk(dir);
  return n;
}

// VitePress with cleanUrls:true emits foo.html and expects the host to
// rewrite /foo/ -> /foo.html. GitHub Pages doesn't, so every browse page
// 404s on its directory-style URL. Convert each non-index .html to
// <name>/index.html so /foo/ resolves natively.
async function rewriteCleanUrls(dir) {
  let count = 0;
  async function walk(d) {
    const entries = await readdir(d, { withFileTypes: true });
    for (const e of entries) {
      const full = join(d, e.name);
      if (e.isDirectory()) {
        await walk(full);
      } else if (e.isFile() && e.name.endsWith(".html") && e.name !== "index.html") {
        const baseName = e.name.slice(0, -5);
        const newDir = join(d, baseName);
        await mkdir(newDir, { recursive: true });
        await rename(full, join(newDir, "index.html"));
        count++;
      }
    }
  }
  await walk(dir);
  return count;
}

function run(cmd, args, env = process.env) {
  const result = spawnSync(cmd, args, {
    stdio: "inherit",
    env,
    shell: process.platform === "win32",
  });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

function runGenerate() {
  console.log("=== Generating formula pages ===");
  run("node", ["generate.js"]);
}

function runVitepressBuild() {
  run("npx", ["vitepress", "build"], {
    ...process.env,
    NODE_OPTIONS: `--max-old-space-size=${MAX_OLD_SPACE}`,
  });
}

async function moveFile(src, dest) {
  await mkdir(dirname(dest), { recursive: true });
  await rename(src, dest);
}

async function mergeBrowseOutput(distRoot, finalRoot) {
  const distBrowse = join(distRoot, "browse");
  if (!(await pathExists(distBrowse))) return 0;

  const finalBrowse = join(finalRoot, "browse");
  await mkdir(finalBrowse, { recursive: true });

  let added = 0;
  const entries = await readdir(distBrowse, { withFileTypes: true });
  for (const e of entries) {
    const src = join(distBrowse, e.name);
    const dest = join(finalBrowse, e.name);
    if (e.isDirectory()) {
      await mkdir(dest, { recursive: true });
      await cp(src, dest, { recursive: true }).catch(() => {});
    } else if (e.isFile() && e.name.endsWith(".html") && e.name !== "index.html") {
      await cp(src, dest).catch(() => {});
      added++;
    }
  }
  return added;
}

async function main() {
  runGenerate();

  console.log("=== Staging browse pages ===");
  await rm(STAGING_DIR, { recursive: true, force: true });
  await rm(FINAL_DIR, { recursive: true, force: true });
  await mkdir(STAGING_DIR, { recursive: true });

  const browseFiles = (await findMarkdownFiles(BROWSE_DIR))
    .filter((f) => !f.endsWith("index.md"));
  for (const f of browseFiles) {
    await moveFile(f, join(STAGING_DIR, relative(BROWSE_DIR, f)));
  }

  console.log("=== Pass 0: Main site (guide, licenses, browse/index) ===");
  runVitepressBuild();
  await rename(DIST_DIR, FINAL_DIR);
  console.log(`Main site built: ${await countHtmlFiles(FINAL_DIR)} pages`);

  const staged = (await findMarkdownFiles(STAGING_DIR)).sort();
  const total = staged.length;
  const numBatches = Math.ceil(total / BATCH_SIZE);
  console.log(
    `=== ${total} formula pages in ${numBatches} batches (batch size: ${BATCH_SIZE}) ===`
  );

  for (let batch = 0; batch < numBatches; batch++) {
    const start = batch * BATCH_SIZE;
    const end = Math.min(start + BATCH_SIZE, total);
    console.log(`\n=== Pass ${batch + 1}: ${end - start} pages (${start + 1}-${end} of ${total}) ===`);

    for (let i = start; i < end; i++) {
      await moveFile(staged[i], join(BROWSE_DIR, relative(STAGING_DIR, staged[i])));
    }

    runVitepressBuild();

    const added = await mergeBrowseOutput(DIST_DIR, FINAL_DIR);
    console.log(`  Added ${added} browse pages`);

    for (let i = start; i < end; i++) {
      const f = staged[i];
      await moveFile(join(BROWSE_DIR, relative(STAGING_DIR, f)), f);
    }

    await rm(DIST_DIR, { recursive: true, force: true });
  }

  await rm(STAGING_DIR, { recursive: true, force: true });
  await rm(DIST_DIR, { recursive: true, force: true });
  await rename(FINAL_DIR, DIST_DIR);

  console.log("=== Rewriting clean URLs to directory style ===");
  const rewritten = await rewriteCleanUrls(DIST_DIR);
  console.log(`Rewrote ${rewritten} pages`);

  console.log("=== Regenerating sitemap ===");
  const sitemapResult = spawnSync("node", ["generate-sitemap.js", DIST_DIR], { stdio: "inherit" });
  if (sitemapResult.status !== 0) process.exit(sitemapResult.status ?? 1);

  console.log(`\n=== Build complete: ${await countHtmlFiles(DIST_DIR)} total HTML pages ===`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
