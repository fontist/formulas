import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";

// The generated trees (browse/, licenses/*.md, public/*.json) are produced
// by `node generate.js` / `node licenses/generate-licenses.js` and stay in
// their historical locations — the loaders read them in place so both
// generators keep working unchanged.
const guide = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./guide" }),
});

const licenses = defineCollection({
  loader: glob({ pattern: ["*.md", "!index.md"], base: "./licenses" }),
});

const browse = defineCollection({
  loader: glob({ pattern: ["**/*.md", "!index.md"], base: "./browse" }),
});

const pages = defineCollection({
  loader: glob({ pattern: "index.md", base: "./" }),
});

export const collections = { guide, licenses, browse, pages };
