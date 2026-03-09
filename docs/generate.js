#!/usr/bin/env node
import * as YAML from "yaml";
import { mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { resolve, join, basename, dirname } from "node:path";
import { glob } from "glob";

const projectRoot = resolve(process.cwd(), "..");

// Configuration
const GITHUB_BRANCH = "v4";
const GITHUB_REPO = "fontist/formulas";

await rm("formulas", { recursive: true, force: true });
await mkdir("formulas", { recursive: true });
await mkdir("public", { recursive: true });

function escapeYAMLString(str) {
  if (!str) return "";
  return str.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

// Detect formula source type from path
function detectSourceType(slug) {
  if (slug.startsWith("google/")) return "google";
  if (slug.startsWith("sil/")) return "sil";
  if (slug.startsWith("macos/")) return "macos";
  return "manual";
}

// Generate inline SVG badge
function svgBadge(label, text, color) {
  const encodedLabel = encodeURIComponent(label);
  const encodedText = encodeURIComponent(text);
  return `<img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='auto' height='20' role='img' aria-label='${label}: ${text}'%3E%3Ctitle%3E${label}: ${text}%3C/title%3E%3ClinearGradient id='b' x2='0' y2='100%25'%3E%3Cstop offset='0' stop-color='%23bbb' stop-opacity='.1'/%3E%3Cstop offset='1' stop-opacity='.1'/%3E%3C/linearGradient%3E%3Cmask id='a'%3E%3Crect width='100%25' height='100%25' fill='%23fff' rx='3'/%3E%3C/mask%3E%3Cg mask='url(%23a)'%3E%3Cpath fill='%23555' d='M0 0h50v20H0z'/%3E%3Cpath fill='${encodeURIComponent(color)}' d='M50 0h80v20H50z'/%3E%3Cpath fill='url(%23b)' d='M0 0h130v20H0z'/%3E%3C/g%3E%3Cg fill='%23fff' text-anchor='middle' font-family='Verdana,Geneva,DejaVu Sans,sans-serif' font-size='11'%3E%3Ctext x='25' y='15'%3E${label}%3C/text%3E%3Ctext x='90' y='15'%3E${text}%3C/text%3E%3C/g%3E%3C/svg%3E" alt="${label}: ${text}">`;
}

// Get source display info
function getSourceInfo(type) {
  const sources = {
    google: {
      name: "Google Fonts",
      badge: svgBadge("Source", "Google Fonts", "#4285f4"),
    },
    sil: {
      name: "SIL International",
      badge: svgBadge("Source", "SIL", "#0066cc"),
    },
    macos: {
      name: "Apple",
      badge: svgBadge("Source", "Apple", "#000000"),
    },
    manual: {
      name: "Manual Formula",
      badge: svgBadge("Source", "Manual", "#6c757d"),
    },
  };
  return sources[type] || sources.manual;
}

// Comprehensive license detection
function detectLicenseInfo(yaml, sourceType) {
  const licenseUrl = (yaml.license_url || "").toLowerCase();
  const requiresLicense = yaml.requires_license_agreement || "";
  const openLicense = yaml.open_license || "";
  let copyright = (yaml.copyright || "").toLowerCase();

  // Also collect copyright from font styles (for formulas without top-level copyright)
  if (!copyright) {
    const styleCopyrights = new Set();
    (yaml.fonts || []).forEach((font) => {
      (font.styles || []).forEach((style) => {
        if (style.copyright) {
          styleCopyrights.add(style.copyright.toLowerCase());
        }
      });
    });
    copyright = [...styleCopyrights].join(" ");
  }

  // Combine all text for license detection
  const allText = `${licenseUrl} ${openLicense} ${copyright}`.toLowerCase();

  // ============================================================
  // PLATFORM RESTRICTED
  // ============================================================

  // macOS fonts
  if (sourceType === "macos") {
    return {
      type: "macos",
      name: "Apple-only License",
      badge: svgBadge("License", "Apple-only", "#f0ad4e"),
      docLink: "/guide/licenses/apple-only",
      spdxUrl: null,
      category: "platform_restricted",
      isOpen: false,
      warning: "⚠️ **Platform Restricted**: These fonts are licensed for use on macOS only. Installation on other platforms may violate Apple's license terms.",
    };
  }

  // ============================================================
  // OPEN SOURCE LICENSES
  // ============================================================

  // SIL Open Font License (OFL)
  if (
    licenseUrl.includes("scripts.sil.org/ofl") ||
    licenseUrl.includes("scripts.sil.org/OFL") ||
    openLicense.toLowerCase().includes("sil open font license") ||
    openLicense.toLowerCase().includes("open font license version 1") ||
    openLicense.toLowerCase().includes("ofl licenses") ||
    openLicense.toLowerCase().includes("dual licensed with mit and ofl") ||
    // Also detect OFL in various contexts
    /\bofl\b/i.test(openLicense) ||  // Standalone "OFL"
    openLicense.includes("开源字体授权") ||  // Chinese: "open font license"
    openLicense.includes("SIL开源字体")  // Chinese: "SIL open font"
  ) {
    return {
      type: "ofl",
      name: "SIL Open Font License 1.1",
      badge: svgBadge("License", "OFL 1.1", "#28a745"),
      docLink: "/guide/licenses/ofl",
      spdxUrl: "https://spdx.org/licenses/OFL-1.1.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Ubuntu Font Licence
  if (
    openLicense.toLowerCase().includes("ubuntu font licence") ||
    copyright.includes("ubuntu font licence")
  ) {
    return {
      type: "ufl",
      name: "Ubuntu Font Licence 1.0",
      badge: svgBadge("License", "UFL 1.0", "#28a745"),
      docLink: "/guide/licenses/ufl",
      spdxUrl: "https://spdx.org/licenses/Ubuntu-font-1.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // GUST Font License (TeX fonts)
  if (
    licenseUrl.includes("gust.org.pl") ||
    openLicense.toLowerCase().includes("gust font license") ||
    licenseUrl.includes("gust")
  ) {
    return {
      type: "gust",
      name: "GUST Font License",
      badge: svgBadge("License", "GUST", "#28a745"),
      docLink: "/guide/licenses/gust",
      spdxUrl: null, // Not on SPDX
      category: "open_source",
      isOpen: true,
    };
  }

  // LGPL (GNU Lesser GPL)
  if (
    licenseUrl.includes("gnu.org/licenses/lgpl") ||
    openLicense.toLowerCase().includes("gnu lesser") ||
    openLicense.toLowerCase().includes("lgpl")
  ) {
    return {
      type: "lgpl",
      name: "GNU LGPL",
      badge: svgBadge("License", "LGPL", "#28a745"),
      docLink: "/guide/licenses/lgpl",
      spdxUrl: "https://spdx.org/licenses/LGPL-3.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Bitstream Vera / DejaVu license
  if (
    licenseUrl.includes("dejavu-fonts.org") ||
    openLicense.toLowerCase().includes("bitstream vera") ||
    copyright.includes("bitstream")
  ) {
    return {
      type: "bitstream",
      name: "Bitstream Vera License",
      badge: svgBadge("License", "Bitstream Vera", "#28a745"),
      docLink: "/guide/licenses/bitstream",
      spdxUrl: "https://spdx.org/licenses/Bitstream-Vera.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Apache License
  if (
    licenseUrl.includes("apache.org/licenses") ||
    licenseUrl.includes("apache-2.0") ||
    openLicense.toLowerCase().includes("apache license") ||
    openLicense.toLowerCase().includes("apache-2.0") ||
    // Material Icons/Symbols from Google are Apache 2.0
    (copyright.includes("google") && copyright.includes("all rights reserved") && sourceType === "google")
  ) {
    return {
      type: "apache",
      name: "Apache License 2.0",
      badge: svgBadge("License", "Apache 2.0", "#28a745"),
      docLink: "/guide/licenses/apache",
      spdxUrl: "https://spdx.org/licenses/Apache-2.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // MIT License
  if (
    licenseUrl.includes("mit-license") ||
    licenseUrl.includes("opensource.org/licenses/mit") ||
    openLicense.toLowerCase().includes("mit license") ||
    openLicense.toLowerCase().includes("mit-license") ||
    openLicense.toLowerCase().includes("dual licensed with mit")
  ) {
    return {
      type: "mit",
      name: "MIT License",
      badge: svgBadge("License", "MIT", "#28a745"),
      docLink: "/guide/licenses/mit",
      spdxUrl: "https://spdx.org/licenses/MIT.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // BSD License
  if (
    licenseUrl.includes("bsd-license") ||
    licenseUrl.includes("opensource.org/licenses/bsd") ||
    openLicense.toLowerCase().includes("bsd license") ||
    openLicense.toLowerCase().includes("redistribution and use in source and binary forms")
  ) {
    return {
      type: "bsd",
      name: "BSD License",
      badge: svgBadge("License", "BSD", "#28a745"),
      docLink: "/guide/licenses/bsd",
      spdxUrl: "https://spdx.org/licenses/BSD-3-Clause.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Public Domain (explicit dedication, not CC0)
  if (
    (openLicense.toLowerCase().includes("public domain") && !licenseUrl.includes("creativecommons.org")) ||
    copyright.includes("public domain") ||
    openLicense.toLowerCase().includes("this font is in the public domain") ||
    openLicense.toLowerCase().includes("released into the public domain") ||
    openLicense.toLowerCase().includes("dedicated to the public domain")
  ) {
    return {
      type: "public_domain",
      name: "Public Domain",
      badge: svgBadge("License", "Public Domain", "#28a745"),
      docLink: "/guide/licenses/public-domain",
      spdxUrl: null, // Public domain is not a license per se
      category: "open_source",
      isOpen: true,
    };
  }

  // Creative Commons CC0 (Public Domain)
  if (
    licenseUrl.includes("creativecommons.org/publicdomain/zero") ||
    licenseUrl.includes("cc0") ||
    openLicense.toLowerCase().includes("creative commons zero") ||
    openLicense.toLowerCase().includes("no rights reserved")
  ) {
    return {
      type: "cc0",
      name: "Creative Commons Zero (Public Domain)",
      badge: svgBadge("License", "CC0 1.0", "#28a745"),
      docLink: "/guide/licenses/cc0",
      spdxUrl: "https://spdx.org/licenses/CC0-1.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Creative Commons BY
  if (
    licenseUrl.includes("creativecommons.org/licenses/by/") ||
    openLicense.toLowerCase().includes("creative commons attribution")
  ) {
    return {
      type: "cc-by",
      name: "Creative Commons Attribution",
      badge: svgBadge("License", "CC BY 4.0", "#28a745"),
      docLink: "/guide/licenses/cc-by",
      spdxUrl: "https://spdx.org/licenses/CC-BY-4.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Creative Commons BY-SA
  if (
    licenseUrl.includes("creativecommons.org/licenses/by-sa/") ||
    openLicense.toLowerCase().includes("creative commons attribution-sharealike")
  ) {
    return {
      type: "cc-by-sa",
      name: "Creative Commons Attribution-ShareAlike",
      badge: svgBadge("License", "CC BY-SA 4.0", "#28a745"),
      docLink: "/guide/licenses/cc-by-sa",
      spdxUrl: "https://spdx.org/licenses/CC-BY-SA-4.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // GNU GPL with Font Exception
  if (
    licenseUrl.includes("gnu.org/licenses/gpl") ||
    openLicense.toLowerCase().includes("gnu general public license") ||
    openLicense.toLowerCase().includes("gpl font exception")
  ) {
    return {
      type: "gpl",
      name: "GNU GPL (with Font Exception)",
      badge: svgBadge("License", "GPL", "#28a745"),
      docLink: "/guide/licenses/gpl",
      spdxUrl: "https://spdx.org/licenses/GPL-3.0.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // IPA Font License (Japanese fonts)
  if (
    licenseUrl.includes("ipafont") ||
    openLicense.toLowerCase().includes("ipa font license")
  ) {
    return {
      type: "ipa",
      name: "IPA Font License",
      badge: svgBadge("License", "IPA", "#28a745"),
      docLink: "/guide/licenses/ipa",
      spdxUrl: "https://spdx.org/licenses/IPA.html",
      category: "open_source",
      isOpen: true,
    };
  }

  // Freeware (free to use but redistribution may be restricted)
  if (
    openLicense.toLowerCase().includes("無料かつ制限なく") || // Japanese: "free and without restriction"
    openLicense.toLowerCase().includes("制限なく利用できます") || // Japanese: "can be used without restriction"
    openLicense.toLowerCase().includes("free to use") ||
    openLicense.toLowerCase().includes("free for personal use") ||
    openLicense.toLowerCase().includes("free for non-commercial")
  ) {
    // Check if redistribution is prohibited
    const isNonRedistributable =
      openLicense.toLowerCase().includes("再配布・販売は禁止") || // Japanese: "redistribution and sales prohibited"
      openLicense.toLowerCase().includes("redistribution prohibited") ||
      openLicense.toLowerCase().includes("redistribution is prohibited") ||
      openLicense.toLowerCase().includes("may not redistribute");

    if (isNonRedistributable) {
      return {
        type: "freeware",
        name: "Freeware (Personal Use Only)",
        badge: svgBadge("License", "Freeware", "#007bff"),
        docLink: "/guide/licenses/freeware",
        spdxUrl: null,
        category: "freely_distributable",
        isOpen: false,
        warning: "🔵 **Freeware**: Free for personal use, but redistribution may be restricted. Check the license terms.",
      };
    }

    return {
      type: "free_use",
      name: "Freely Usable",
      badge: svgBadge("License", "Free to Use", "#28a745"),
      docLink: "/guide/licenses/free-use",
      spdxUrl: null,
      category: "open_source",
      isOpen: true,
    };
  }

  // Freely usable (no license required)
  if (
    openLicense.toLowerCase().includes("requires no licenc") ||
    openLicense.toLowerCase().includes("requires no licens") ||
    openLicense.toLowerCase().includes("no license required") ||
    openLicense.toLowerCase().includes("no licenc required")
  ) {
    return {
      type: "free_use",
      name: "Freely Usable",
      badge: svgBadge("License", "Free to Use", "#28a745"),
      docLink: "/guide/licenses/free-use",
      spdxUrl: null,
      category: "open_source",
      isOpen: true,
    };
  }

  // Free for commercial use
  if (
    openLicense.toLowerCase().includes("free") &&
    openLicense.toLowerCase().includes("commercial")
  ) {
    return {
      type: "free_commercial",
      name: "Free for Commercial Use",
      badge: svgBadge("License", "Free Commercial", "#28a745"),
      docLink: "/guide/licenses/free-use",
      spdxUrl: null,
      category: "open_source",
      isOpen: true,
    };
  }

  // ============================================================
  // FREELY DISTRIBUTABLE (Not Open Source)
  // ============================================================

  // Microsoft Web Fonts (freely distributable)
  if (
    requiresLicense.includes("Microsoft") &&
    (requiresLicense.includes("reproduce and distribute an unlimited number of copies") ||
     requiresLicense.includes("TrueType core fonts for the Web EULA") ||
     requiresLicense.includes("web.archive.org"))
  ) {
    return {
      type: "ms_web_fonts",
      name: "Microsoft Web Fonts EULA",
      badge: svgBadge("License", "Freely Distributable", "#007bff"),
      docLink: "/guide/licenses/microsoft-web",
      spdxUrl: null,
      category: "freely_distributable",
      isOpen: false,
      warning: "📋 **Freely Distributable**: These fonts may be redistributed under the Microsoft Web Fonts EULA. You may distribute unlimited copies (not for profit, include EULA).",
    };
  }

  // ============================================================
  // BUNDLED SOFTWARE FONTS
  // ============================================================
  // Fonts that come with specific software (Microsoft Office, Adobe, etc.)

  // Microsoft Office/Windows fonts
  if (requiresLicense.includes("MICROSOFT SOFTWARE LICENSE") ||
      requiresLicense.includes("MICROSOFT OFFICE") ||
      (requiresLicense.includes("Microsoft") && requiresLicense.includes("license agreement"))) {
    return {
      type: "ms_office",
      name: "Microsoft Software License",
      badge: svgBadge("License", "MS Software", "#8b5cf6"),
      docLink: "/guide/licenses/ms-office",
      spdxUrl: null,
      category: "bundled_software",
      isOpen: false,
      warning: "📦 **Bundled with Microsoft Software**: These fonts come with Microsoft Office or Windows. Install the Microsoft software to use these fonts.",
    };
  }

  // Adobe fonts
  if (requiresLicense.includes("Adobe") || licenseUrl.includes("adobe.com")) {
    return {
      type: "adobe",
      name: "Adobe Software License",
      badge: svgBadge("License", "Adobe Software", "#8b5cf6"),
      docLink: "/guide/licenses/adobe",
      spdxUrl: null,
      category: "bundled_software",
      isOpen: false,
      warning: "📦 **Bundled with Adobe Software**: These fonts come with Adobe products. Install Adobe software to use these fonts.",
    };
  }

  // Any other license agreement
  if (requiresLicense) {
    return {
      type: "bundled",
      name: "Software Bundle License",
      badge: svgBadge("License", "Bundled Software", "#8b5cf6"),
      docLink: "/guide/licenses/bundled",
      spdxUrl: null,
      category: "bundled_software",
      isOpen: false,
      warning: "📦 **Bundled with Software**: This font comes with specific software. Check the license agreement for terms.",
    };
  }

  // ============================================================
  // LICENSE UNKNOWN - ASK USER TO DETERMINE
  // ============================================================
  // Missing license info does NOT mean proprietary. Ask user to check.

  return {
    type: "unknown",
    name: "License Not Specified",
    badge: svgBadge("License", "Check Source", "#17a2b8"),
    docLink: "/guide/licenses/unknown",
    spdxUrl: null,
    category: "unknown",
    isOpen: false,
    warning: "📋 **License Not Specified**: This formula does not contain license information. Please check the font source or homepage to determine the license terms before use.",
  };
}

// Get the formula name (used for install command) from slug
function getFormulaName(slug) {
  return slug.split("/").pop();
}

const allFormulas = [];

// Process all formula files
const formulaFiles = await glob("**/*.y{a,}ml", {
  cwd: join(projectRoot, "Formulas"),
  nodir: true,
});

for (const relativeFilePath of formulaFiles) {
  const absoluteFilePath = join(projectRoot, "Formulas", relativeFilePath);
  const text = await readFile(absoluteFilePath, "utf8");
  const yamls = YAML.parseAllDocuments(text).map((x) => x.toJSON());
  const yaml = yamls.reduce((a, x) => Object.assign(a, x), {});
  const slug = relativeFilePath.replace(/\.ya?ml$/, "");

  const githubURL = `https://github.com/${GITHUB_REPO}/blob/${GITHUB_BRANCH}/Formulas/${relativeFilePath}`;
  const displayName = yaml.name || yaml.description || basename(slug);
  const formulaName = getFormulaName(slug);

  // Detect source and license
  const sourceType = detectSourceType(slug);
  const sourceInfo = getSourceInfo(sourceType);
  const licenseInfo = detectLicenseInfo(yaml, sourceType);

  // Collect font families (from both fonts and font_collections)
  const fontFamilies = {};
  const allStyles = [];
  const allCopyrights = new Set();

  // Process regular fonts
  (yaml.fonts || []).forEach((font) => {
    const familyName = font.name;
    if (!fontFamilies[familyName]) {
      fontFamilies[familyName] = [];
    }

    (font.styles || []).forEach((style) => {
      const styleInfo = {
        family_name: style.family_name || familyName,
        type: style.type || "Regular",
        full_name: style.full_name,
        post_script_name: style.post_script_name,
        version: style.version,
        font: style.font,
        copyright: style.copyright,
      };

      fontFamilies[familyName].push(styleInfo);
      allStyles.push(styleInfo);

      if (style.copyright) allCopyrights.add(style.copyright);
    });
  });

  // Also process font_collections (TTC files)
  (yaml.font_collections || []).forEach((collection) => {
    (collection.fonts || []).forEach((font) => {
      const familyName = font.name;
      if (!fontFamilies[familyName]) {
        fontFamilies[familyName] = [];
      }

      (font.styles || []).forEach((style) => {
        const styleInfo = {
          family_name: style.family_name || familyName,
          type: style.type || "Regular",
          full_name: style.full_name,
          post_script_name: style.post_script_name,
          version: style.version,
          font: style.font || collection.filename,
          copyright: style.copyright,
          collection_file: collection.filename,
        };

        fontFamilies[familyName].push(styleInfo);
        allStyles.push(styleInfo);

        if (style.copyright) allCopyrights.add(style.copyright);
      });
    });
  });

  // Process font collections (TTC files)
  (yaml.font_collections || []).forEach((collection) => {
    (collection.fonts || []).forEach((font) => {
      const familyName = font.name;
      if (!fontFamilies[familyName]) {
        fontFamilies[familyName] = [];
      }

      (font.styles || []).forEach((style) => {
        const styleInfo = {
          family_name: style.family_name || style.preferred_family_name || familyName,
          type: style.type || "Regular",
          full_name: style.full_name,
          post_script_name: style.post_script_name,
          version: style.version,
          font: style.font,
          copyright: style.copyright,
          collection_file: collection.filename,
        };

        fontFamilies[familyName].push(styleInfo);
        allStyles.push(styleInfo);

        if (style.copyright) allCopyrights.add(style.copyright);
      });
    });
  });

  // Build resources section
  let resourcesSection = "";
  const resources = yaml.resources || {};
  if (Object.keys(resources).length > 0) {
    const resourceEntries = Object.entries(resources).flatMap(([name, resource]) => {
      if (resource.urls && resource.urls.length > 0) {
        const sizeKB = resource.file_size
          ? `${(resource.file_size / 1024).toFixed(1)} KB`
          : "Unknown";
        const shaShort =
          resource.sha256 && typeof resource.sha256 === "string"
            ? `\`${resource.sha256.substring(0, 12)}...\``
            : "N/A";
        return resource.urls.map((url, index) => ({
          name: resource.urls.length > 1 ? `${name} (mirror ${index + 1})` : name,
          sizeKB,
          shaShort,
          downloadUrl: url,
        }));
      }
      if (resource.files && resource.files.length > 0) {
        return resource.files.map((url) => {
          const fileName = url.split("/").pop();
          return {
            name: fileName,
            sizeKB: "Direct",
            shaShort: "N/A",
            downloadUrl: url,
          };
        });
      }
      return [];
    });

    if (resourceEntries.length > 0) {
      resourcesSection = `## Resources

| File | Size | SHA256 | Download |
|------|------|--------|----------|
${resourceEntries
  .map((entry) => `| ${entry.name} | ${entry.sizeKB} | ${entry.shaShort} | [Download](${entry.downloadUrl}) |`)
  .join("\n")}
`;
    }
  }

  // Build fonts section
  let fontsSection = "";
  const familyNames = Object.keys(fontFamilies);
  if (familyNames.length > 0) {
    fontsSection = `## Font Families

${familyNames
  .map((familyName) => {
    const styles = fontFamilies[familyName];
    const uniqueTypes = [...new Set(styles.map((s) => s.type))];

    return `### ${familyName}

*${styles.length} styles: ${uniqueTypes.join(", ")}*

| Style | Font File | PostScript Name | Version |
|-------|-----------|-----------------|---------|
${styles
  .map((style) => {
    const fontFile = style.font || "N/A";
    const psName = style.post_script_name || "N/A";
    const version = style.version
      ? style.version.split(";")[0].trim()
      : "N/A";
    return `| ${style.type} | \`${fontFile}\` | ${psName} | ${version} |`;
  })
  .join("\n")}`;
  })
  .join("\n\n")}
`;
  }

  // Build license section
  const licenseLinks = [];
  if (licenseInfo.docLink) {
    licenseLinks.push(`[→ Learn more](${licenseInfo.docLink})`);
  }
  if (licenseInfo.spdxUrl) {
    licenseLinks.push(`[SPDX](${licenseInfo.spdxUrl})`);
  }
  const licenseLinksText = licenseLinks.length > 0 ? ` ${licenseLinks.join(" · ")}` : "";

  let licenseSection = `## License

${licenseInfo.badge}

**${licenseInfo.name}**${licenseLinksText}

${licenseInfo.warning || ""}
${
  yaml.license_url
    ? `\nLicense details: [${yaml.license_url}](${yaml.license_url})`
    : ""
}
${
  yaml.requires_license_agreement
    ? `

<details>
<summary>View License Agreement</summary>

\`\`\`
${yaml.requires_license_agreement.substring(0, 2000)}${yaml.requires_license_agreement.length > 2000 ? "..." : ""}
\`\`\`

</details>
`
    : ""
}
`;

  // Build copyright section
  let copyrightSection = "";
  if (allCopyrights.size > 0) {
    copyrightSection = `## Copyright

${[...allCopyrights]
  .map((c) => `- ${c.replace(/</g, "&lt;").replace(/>/g, "&gt;")}`)
  .join("\n")}
`;
  }

  // Build install command
  const installCmd = `fontist install "${formulaName}"`;

  // Generate meta description
  const styleCount = allStyles.length;
  const familyCount = familyNames.length;
  const metaDescription = `${displayName} font package for Fontist. ${familyCount} font families, ${styleCount} styles. Install: fontist install "${formulaName}"`;

  // Build badges
  const badges = [licenseInfo.badge, sourceInfo.badge].join(" ");

  // Build source section
  const sourceSection = `## Source

${sourceInfo.badge}

- **Type**: ${sourceInfo.name}
- **Formula**: [View on GitHub](${githubURL})
${yaml.homepage ? `- **Homepage**: [${yaml.homepage}](${yaml.homepage})` : ""}`;

  // Build complete markdown
  const md = `\
---
title: "${displayName} - Fontist Formula"
description: "${escapeYAMLString(metaDescription)}"
outline: [2, 3]
---

# ${displayName}

${badges}

${yaml.description || ""}

## Quick Install

\`\`\`bash
${installCmd}
\`\`\`

${sourceSection}

${resourcesSection}
${fontsSection}
${copyrightSection}
${licenseSection}
`;

  await mkdir(dirname(`formulas/${slug}.md`), { recursive: true });
  await writeFile(`formulas/${slug}.md`, md);

  // Collect for index
  allFormulas.push({
    name: displayName,
    formulaName,
    slug,
    styleCount: allStyles.length,
    familyCount: familyNames.length,
    familyNames,
    sourceType,
    platforms: yaml.platforms || [],
    licenseType: licenseInfo.type,
    licenseCategory: licenseInfo.category,
    licenseName: licenseInfo.name,
    isOpen: licenseInfo.isOpen,
    githubURL,
    homepage: yaml.homepage,
  });
}

// Generate formulas data JSON for client-side filtering
const formulasJson = allFormulas.map((f) => ({
  name: f.name,
  formulaName: f.formulaName,
  slug: f.slug,
  familyCount: f.familyCount,
  styleCount: f.styleCount,
  familyNames: f.familyNames,
  sourceType: f.sourceType,
  platforms: f.platforms || [],
  licenseType: f.licenseType,
  licenseCategory: f.licenseCategory,
  licenseName: f.licenseName,
}));

await writeFile("public/formulas-data.json", JSON.stringify(formulasJson, null, 2));

// Generate Vue-based interactive index page
const indexMd = `\
---
search: false
outline: false
---

# All Formulas

<FormulaBrowser />
`;

await writeFile(`formulas/index.md`, indexMd);

console.log(`Generated ${allFormulas.length} formula pages`);
