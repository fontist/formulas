#!/usr/bin/env node
import * as YAML from "yaml";
import { mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { resolve, join, basename, dirname } from "node:path";
// import { marked } from 'marked'
import { glob } from "glob";

const projectRoot = resolve(process.cwd(), "..");

await rm("formulas", { recursive: true, force: true });
await mkdir("formulas", { recursive: true });

function escapeHTML(html) {
  return html.replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

const allFormulas = [];

for (const relativeFilePath of await glob("**/*.y{a,}ml", {
  cwd: join(projectRoot, "Formulas"),
  nodir: true,
})) {
  const absoluteFilePath = join(projectRoot, "Formulas", relativeFilePath);
  const text = await readFile(absoluteFilePath, "utf8");
  const yamls = YAML.parseAllDocuments(text).map((x) => x.toJSON());
  const yaml = yamls.reduce((a, x) => Object.assign(a, x), {});
  const slug = relativeFilePath.replace(/\.ya?ml$/, "");
  // const licenseHTML = marked(yaml.requires_license_agreement || "", { breaks: true })
  const fontNames = (yaml.fonts ?? [])
    .flatMap((font) => font.styles ?? [])
    .map((style) => {
      if (style.type) {
        return `${style.family_name} (${style.type})`;
      } else {
        return style.family_name;
      }
    });
  const githubURL = `https://github.com/fontist/formulas/blob/main/Formulas/${relativeFilePath}`;

  const name = yaml.name || yaml.description || basename(slug);

  // TODO: Get the local search to only search specific parts of this
  // generated markdown. Namely just the name, description, and list of fonts.
  const md = `\
---
outline: false
---

# ${name}

${yaml.description || ""}

[📜 View source](${githubURL})

${fontNames.map((font) => `- ${font}`).join("\n")}

${escapeHTML(yaml.copyright || "")}

${yaml.license_url ? `[${yaml.license_url}](${yaml.license_url})` : ""}`;

  await mkdir(dirname(`formulas/${slug}.md`), { recursive: true });
  await writeFile(`formulas/${slug}.md`, md);
  // console.log(`Wrote formula/${slug}.md`)

  allFormulas.push({
    name,
    slug,
    fontNames,
    githubURL,
  });
}

const md = `\
---
search: false
outline: false
---

# All Formulas

${allFormulas
  .map(
    (formula) => `\
- [${formula.name}](/formulas/${formula.slug}) \\
    ${formula.fontNames.join(", ")}`,
  )
  .join("\n\n")}
`;
await writeFile(`formulas/index.md`, md);
