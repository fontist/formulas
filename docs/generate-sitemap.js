#!/usr/bin/env node
// Regenerate dist/sitemap.xml from the final dist/ structure.
//
// VitePress's built-in sitemap config only sees the pages from its own build
// — in the multi-batch CI pipeline (docs.yml build-main + build-batch matrix)
// each batch's sitemap lists only that batch's pages. The combine job deploys
// dist-main's sitemap, which is missing all 4,283 formula browse pages that
// were merged in from the batches.
//
// Run this AFTER all browse pages have been merged AND the clean-URLs post-
// process has converted foo.html -> foo/index.html. The script scans dist/
// for index.html files and emits one <url> entry per page.

import { readdir, stat, writeFile } from "node:fs/promises";
import { join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const DIST = process.argv[2] || join(__dirname, "..", ".vitepress", "dist");
const ORIGIN = process.env.SITE_URL || "http://localhost:5173";
const BASE_PATH = process.env.BASE_PATH || "/formulas/";

// 404 etc. shouldn't appear in the sitemap.
const EXCLUDE_PATHS = new Set(["404"]);

async function findIndexFiles(dir) {
  const out = [];
  const entries = await readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      out.push(...await findIndexFiles(full));
    } else if (e.name === "index.html") {
      out.push(full);
    }
  }
  return out;
}

function escapeXml(s) {
  return s.replace(/[<>&'"]/g, (c) => ({
    "<": "&lt;",
    ">": "&gt;",
    "&": "&amp;",
    "'": "&apos;",
    '"': "&quot;",
  }[c]));
}

async function main() {
  const files = await findIndexFiles(DIST);
  const entries = [];
  for (const f of files) {
    const relPath = relative(DIST, f).split(sep).slice(0, -1).join("/");
    if (EXCLUDE_PATHS.has(relPath)) continue;
    const url = `${BASE_PATH}${relPath}/`.replace(/\/{2,}/g, "/");
    let lastmod;
    try {
      lastmod = (await stat(f)).mtime.toISOString();
    } catch {
      lastmod = new Date().toISOString();
    }
    entries.push(
      `  <url><loc>${escapeXml(`${ORIGIN}${url}`)}</loc><lastmod>${lastmod}</lastmod></url>`
    );
  }
  // Stable sort by URL for reproducible builds.
  entries.sort();
  const xml =
    `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    `${entries.join("\n")}\n` +
    `</urlset>\n`;
  await writeFile(join(DIST, "sitemap.xml"), xml);
  console.log(`Generated sitemap.xml with ${entries.length} URLs`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
