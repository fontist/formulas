#!/usr/bin/env node
import * as YAML from "yaml"
import { mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises"
import { resolve, join, basename, dirname } from "node:path"
import { marked } from 'marked'
import { glob } from "glob"

const projectRoot = resolve(process.cwd(), "..")

await rm("formula", { recursive: true, force: true })
await mkdir("formula", { recursive: true })

function escapeHTML(html) {
  return html.replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

for (const relativeFilePath of await glob("**/*.y{a,}ml", { cwd: join(projectRoot, "Formulas"), nodir: true })) {
  const absoluteFilePath = join(projectRoot, "Formulas", relativeFilePath)
  const text = await readFile(absoluteFilePath, "utf8")
  const yamls = YAML.parseAllDocuments(text).map(x => x.toJSON())
  const yaml = yamls.reduce((a, x) => Object.assign(a, x), {})
  const slug = relativeFilePath.replace(/\.ya?ml$/, "")
  const licenseHTML = marked(yaml.requires_license_agreement || "", { breaks: true })
  const fontNames = (yaml.fonts ?? []).flatMap(font => font.styles ?? []).map(style => {
    if (style.type) {
      return `${style.family_name} (${style.type})`
    } else {
      return style.family_name
    }
  })
  const githubURL = `https://github.com/fontist/formulas/blob/main/Formulas/${relativeFilePath}`

  const name = yaml.name || yaml.description || basename(slug)

  const md = `\
# ${name}

${yaml.description || ""}

[📜 View source recipe](${githubURL})

${fontNames.map(font => `- ${font}`).join("\n")}

${escapeHTML(yaml.copyright || "")}

${yaml.license_url ? `[${yaml.license_url}](${yaml.license_url})` : ""}`

  await mkdir(dirname(`formula/${slug}.md`), { recursive: true });
  await writeFile(`formula/${slug}.md`, md)
  console.log(`Wrote formula/${slug}.md`)
}
