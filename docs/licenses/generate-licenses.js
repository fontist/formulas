import * as YAML from "yaml";
import { readdir, readFile, writeFile } from "node:fs/promises";
import { resolve, join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..", "..");
const licensesDir = join(__dirname);
const dataDir = join(__dirname, "data");

// Generate inline SVG badge
function svgBadge(label, text, color) {
  return `<img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='auto' height='20' role='img' aria-label='${label}: ${text}'%3E%3Ctitle%3E${label}: ${text}%3C/title%3E%3ClinearGradient id='b' x2='0' y2='100%25'%3E%3Cstop offset='0' stop-color='%23bbb' stop-opacity='.1'/%3E%3Cstop offset='1' stop-opacity='.1'/%3E%3C/linearGradient%3E%3Cmask id='a'%3E%3Crect width='100%25' height='100%25' fill='%23fff' rx='3'/%3E%3C/mask%3E%3Cg mask='url(%23a)'%3E%3Cpath fill='%23555' d='M0 0h50v20H0z'/%3E%3Cpath fill='${encodeURIComponent(color)}' d='M50 0h80v20H50z'/%3E%3Cpath fill='url(%23b)' d='M0 0h130v20H0z'/%3E%3C/g%3E%3Cg fill='%23fff' text-anchor='middle' font-family='Verdana,Geneva,DejaVu Sans,sans-serif' font-size='11'%3E%3Ctext x='25' y='15'%3E${label}%3C/text%3E%3Ctext x='90' y='15'%3E${text}%3C/text%3E%3C/g%3E%3C/svg%3E" alt="${label}: ${text}">`;
}

// Category badge text mapping
const categoryLabels = {
  open_source: "Open Source",
  bundled_software: "Bundled Software",
  platform_restricted: "Platform Restricted",
  freely_distributable: "Freely Distributable",
  unknown: "Unknown",
};

// Read sample license text from formula
async function getSampleLicenseText(sampleFormula) {
  if (!sampleFormula) return null;

  try {
    const formulaPath = join(projectRoot, "Formulas", `${sampleFormula}.yml`);
    const content = await readFile(formulaPath, "utf8");
    const yaml = YAML.parse(content);

    if (yaml.requires_license_agreement) {
      return {
        text: yaml.requires_license_agreement,
        source: sampleFormula,
        type: "requires_license_agreement"
      };
    }
    if (yaml.open_license) {
      return {
        text: yaml.open_license,
        source: sampleFormula,
        type: "open_license"
      };
    }
    return null;
  } catch (e) {
    console.warn(`Warning: Could not read sample formula ${sampleFormula}: ${e.message}`);
    return null;
  }
}

// Generate markdown for a license
async function generateLicenseMarkdown(licenseData) {
  const { id, name, spdx_id, spdx_url, badge_color, category, summary, permissions, see_also, sample_formula } = licenseData;

  const licenseBadge = svgBadge("License", name.replace(/ License.*/, ""), badge_color);
  const categoryBadge = svgBadge("Category", categoryLabels[category] || category, badge_color);

  let spdxSection = "";
  if (spdx_id && spdx_url) {
    spdxSection = `**SPDX Identifier:** ${spdx_id}\n\n**SPDX Page:** ${spdx_url}`;
  } else if (spdx_id) {
    spdxSection = `**SPDX Identifier:** ${spdx_id}`;
  } else {
    spdxSection = "**SPDX Identifier:** Not on SPDX";
  }

  let permissionsSection = "";

  if (permissions.allows && permissions.allows.length > 0) {
    permissionsSection += `### ✅ Allows For\n\n`;
    permissionsSection += `| Context | Permission | Notes |\n|---------|------------|-------|\n`;
    permissionsSection += permissions.allows.map(p =>
      `| ${p.context} | ✅ ${p.permission} | ${p.notes || ""} |`
    ).join("\n");
    permissionsSection += "\n\n";
  }

  if (permissions.conditional && permissions.conditional.length > 0) {
    permissionsSection += `### ⚠️ Conditional\n\n`;
    permissionsSection += `| Permission | Condition |\n|------------|-----------|\n`;
    permissionsSection += permissions.conditional.map(p =>
      `| ${p.permission} | ${p.condition} |`
    ).join("\n");
    permissionsSection += "\n\n";
  }

  if (permissions.disallows && permissions.disallows.length > 0) {
    permissionsSection += `### ❌ Disallows For\n\n`;
    permissionsSection += `| Permission | Notes |\n|------------|-------|\n`;
    permissionsSection += permissions.disallows.map(p =>
      `| ${p.permission} | ${p.notes || ""} |`
    ).join("\n");
    permissionsSection += "\n\n";
  }

  let sampleLicenseSection = "";
  const sampleLicense = await getSampleLicenseText(sample_formula);
  if (sampleLicense) {
    const truncatedText = sampleLicense.text.length > 5000
      ? sampleLicense.text.substring(0, 5000) + "\n\n[... truncated for display ...]"
      : sampleLicense.text;

    sampleLicenseSection = `## Sample License Text\n\n`;
    sampleLicenseSection += `From formula: \`${sample_formula}\`\n\n`;
    sampleLicenseSection += `<details>\n`;
    sampleLicenseSection += `<summary>View Full License Text</summary>\n\n`;
    sampleLicenseSection += "```\n";
    sampleLicenseSection += truncatedText;
    sampleLicenseSection += "\n```\n\n";
    sampleLicenseSection += `</details>\n\n`;
  }

  let seeAlsoSection = "";
  if (see_also && see_also.length > 0) {
    seeAlsoSection = `## See Also\n\n`;
    seeAlsoSection += see_also.map(link => `- [${link.title}](${link.url})`).join("\n");
    seeAlsoSection += "\n";
  }

  const md = `# ${name}

${licenseBadge} ${categoryBadge}

${spdxSection}

## Quick Summary

${summary}

## Permissions Overview

${permissionsSection}
${sampleLicenseSection}
${seeAlsoSection}
`;

  return md;
}

// Export function for use by generate.js
export async function generateLicenses() {
  const files = await readdir(dataDir);
  const yamlFiles = files.filter(f => f.endsWith(".yml") || f.endsWith(".yaml"));

  let count = 0;
  for (const file of yamlFiles) {
    const content = await readFile(join(dataDir, file), "utf8");
    const licenseData = YAML.parse(content);

    const md = await generateLicenseMarkdown(licenseData);
    const outPath = join(licensesDir, `${licenseData.id}.md`);

    await writeFile(outPath, md);
    count++;
  }

  console.log(`Generated ${count} license pages from YAML data`);
}

// Also allow running standalone
const isMain = import.meta.url === `file://${process.argv[1].replace(/\\/g, '/')}`;
if (isMain) {
  generateLicenses().catch(console.error);
}
