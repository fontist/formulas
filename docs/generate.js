#!/usr/bin/env node
import * as YAML from "yaml";
import { mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { resolve, join, basename, dirname } from "node:path";
import { glob } from "glob";

const projectRoot = resolve(process.cwd(), "..");

// Configuration
const GITHUB_BRANCH = "v5";
const GITHUB_REPO = "fontist/formulas";

await rm("browse", { recursive: true, force: true });
await mkdir("browse", { recursive: true });
await mkdir("public", { recursive: true });

function escapeYAMLString(str) {
  if (!str) return "";
  return str.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

// Prevent markdown autolinking of bare URLs in body text (descriptions,
// copyrights). The backslash escapes the colon so markdown-it renders the
// URL as plain text instead of an <a href>. License/EULA body text is
// already safe — it ships inside ```code blocks```.
function escapeBareUrls(str) {
  if (!str) return "";
  return str.replace(/(https?:)(\/\/)/g, "$1\\$2");
}

function slugify(str) {
  return String(str)
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");
}

// Detect formula source type from path
function detectSourceType(slug) {
  if (slug.startsWith("google/")) return "google";
  if (slug.startsWith("sil/")) return "sil";
  if (slug.startsWith("macos/")) return "macos";
  return "manual";
}

function badgeCategory(color) {
  const c = (color || "").toLowerCase();
  if (c === "#28a745") return "open";
  if (c === "#f0ad4e") return "platform";
  if (c === "#007bff") return "freely";
  if (c === "#8b5cf6") return "bundled";
  return "other";
}

function chipBadge(label, text, color, _textWidth) {
  const cat = badgeCategory(color);
  return `<span class="detail-chip detail-chip--lic detail-chip--${cat}" title="${label}: ${text}"><span class="detail-chip-dot"></span><span class="detail-chip-k">${label}</span><span class="detail-chip-v">${text}</span></span>`;
}

const v5Tag = '<span class="v5-tag" title="New in Formula v5">v5</span>';

function getSourceInfo(type) {
  const sources = {
    google: {
      name: "Google Fonts",
      badge: `<img src="/sources/google.svg" alt="Google Fonts" class="source-badge" title="Google Fonts">`,
    },
    sil: {
      name: "SIL International",
      badge: `<img src="/sources/sil.svg" alt="SIL International" class="source-badge" title="SIL International">`,
    },
    macos: {
      name: "Apple",
      badge: `<img src="/sources/apple.svg" alt="Apple" class="source-badge" title="Apple">`,
    },
    manual: {
      name: "Expert Curated",
      badge: `<img src="/sources/fontist.svg" alt="Expert Curated" class="source-badge" title="Expert Curated">`,
    },
  };
  const info = sources[type] || sources.manual;
  info.chip = `<span class="detail-chip detail-chip--src" title="${info.name}"><span class="detail-chip-k">Source</span><span class="detail-chip-v">${info.name}</span></span>`;
  return info;
}

// Comprehensive license detection
function detectLicenseInfo(yaml, sourceType) {
  const licenseUrl = (yaml.license_url || "").toLowerCase();
  const requiresLicense = yaml.requires_license_agreement || "";
  const openLicense = yaml.open_license || "";
  const spdxLicense = (yaml.spdx_license || "").toUpperCase();
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

  // Platform-tied sources (macOS) win over SPDX detection: a macOS font is
  // platform_restricted regardless of any SPDX code on the formula, because
  // the SPDX code (often LicenseRef-Apple-EA1705) describes the EULA text,
  // not the redistribution category. Without this guard, all 2,107 macOS
  // fonts get miscategorized as open_source via the SPDX fallback below.
  if (sourceType === "macos") {
    return {
      type: "macos",
      name: "Apple-only License",
      badge: chipBadge("License", "Apple-only", "#f0ad4e", 120),
      docLink: "/licenses/apple-only",
      spdxUrl: null,
      category: "platform_restricted",
      isOpen: false,
      warning: "⚠️ **Platform Restricted**: These fonts are licensed for use on macOS only. Installation on other platforms may violate Apple's license terms.",
    };
  }

  // Fast path: use spdx_license field if available
  if (spdxLicense) {
    if (spdxLicense.startsWith("OFL-1.1")) {
      const isRfn = spdxLicense.includes("-RFN");
      // SPDX URLs are case-sensitive: OFL-1.1-RFN.html and OFL-1.1-no-RFN.html
      // exist, but OFL-1.1-NO-RFN.html does not. YAML stores it uppercase.
      const spdxPath = spdxLicense.replace("-NO-RFN", "-no-RFN");
      return {
        type: "ofl",
        name: `SIL Open Font License 1.1${isRfn ? " (with RFN)" : ""}`,
        badge: chipBadge("License", isRfn ? "OFL 1.1-RFN" : "OFL 1.1", "#28a745", isRfn ? 140 : 120),
        docLink: "/licenses/ofl",
        spdxUrl: `https://spdx.org/licenses/${spdxPath}.html`,
        category: "open_source",
        isOpen: true,
      };
    }
    if (spdxLicense === "APACHE-2.0") {
      return {
        type: "apache", name: "Apache License 2.0",
        badge: chipBadge("License", "Apache 2.0", "#28a745", 120),
        docLink: "/licenses/apache", spdxUrl: "https://spdx.org/licenses/Apache-2.0.html",
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense === "MIT") {
      return {
        type: "mit", name: "MIT License",
        badge: chipBadge("License", "MIT", "#28a745", 120),
        docLink: "/licenses/mit", spdxUrl: "https://spdx.org/licenses/MIT.html",
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("CC0-")) {
      return {
        type: "cc0", name: "Creative Commons Zero (Public Domain)",
        badge: chipBadge("License", "CC0 1.0", "#28a745", 120),
        docLink: "/licenses/cc0", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("CC-BY-")) {
      return {
        type: "cc-by", name: "Creative Commons Attribution",
        badge: chipBadge("License", "CC BY 4.0", "#28a745", 120),
        docLink: "/licenses/cc-by", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("CC-BY-SA-")) {
      return {
        type: "cc-by-sa", name: "Creative Commons Attribution-ShareAlike",
        badge: chipBadge("License", "CC BY-SA 4.0", "#28a745", 120),
        docLink: "/licenses/cc-by-sa", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("GPL-") || spdxLicense.includes("GPL")) {
      return {
        type: "gpl", name: "GNU GPL (with Font Exception)",
        badge: chipBadge("License", "GPL", "#28a745", 120),
        docLink: "/licenses/gpl", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("LGPL-")) {
      return {
        type: "lgpl", name: "GNU LGPL",
        badge: chipBadge("License", "LGPL", "#28a745", 120),
        docLink: "/licenses/lgpl", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("UBUNTU-FONT-")) {
      return {
        type: "ufl", name: "Ubuntu Font Licence 1.0",
        badge: chipBadge("License", "UFL 1.0", "#28a745", 120),
        docLink: "/licenses/ufl", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    if (spdxLicense.startsWith("IPA")) {
      return {
        type: "ipa", name: "IPA Font License",
        badge: chipBadge("License", "IPA", "#28a745", 120),
        docLink: "/licenses/ipa", spdxUrl: `https://spdx.org/licenses/${spdxLicense}.html`,
        category: "open_source", isOpen: true,
      };
    }
    // Generic fallback for SPDX codes not matched above.
    // LicenseRef-* codes are vendor-specific references with no SPDX page
    // (spdxUrl=null). Categorize by vendor prefix so the browse page and
    // stats reflect the right redistribution category instead of dumping
    // everything into open_source.
    const isLicenseRef = spdxLicense.startsWith("LICENSEREF-");
    let refType = "spdx_other";
    let refCategory = "open_source";
    let refBadgeText = spdxLicense.slice(0, 15);
    let refBadgeColor = "#28a745";
    if (isLicenseRef) {
      if (spdxLicense.startsWith("LICENSEREF-APPLE-")) {
        refType = "macos"; refCategory = "platform_restricted";
        refBadgeText = "Apple-only"; refBadgeColor = "#f0ad4e";
      } else if (spdxLicense.startsWith("LICENSEREF-MICROSOFT-FONTPACK-")) {
        refType = "ms_web_fonts"; refCategory = "freely_distributable";
        refBadgeText = "MS Web Fonts"; refBadgeColor = "#007bff";
      } else if (spdxLicense.startsWith("LICENSEREF-MICROSOFT-")) {
        refType = "ms_office"; refCategory = "bundled_software";
        refBadgeText = "MS Software"; refBadgeColor = "#8b5cf6";
      } else if (spdxLicense.startsWith("LICENSEREF-ADOBE-")) {
        refType = "adobe"; refCategory = "bundled_software";
        refBadgeText = "Adobe Software"; refBadgeColor = "#8b5cf6";
      }
    }
    return {
      type: refType, name: spdxLicense,
      badge: chipBadge("License", refBadgeText, refBadgeColor, 120),
      docLink: null, spdxUrl: isLicenseRef ? null : `https://spdx.org/licenses/${spdxLicense}.html`,
      category: refCategory, isOpen: refCategory === "open_source",
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
      badge: chipBadge("License", "OFL 1.1", "#28a745", 120),
      docLink: "/licenses/ofl",
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
      badge: chipBadge("License", "UFL 1.0", "#28a745", 120),
      docLink: "/licenses/ufl",
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
      badge: chipBadge("License", "GUST", "#28a745", 120),
      docLink: "/licenses/gust",
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
      badge: chipBadge("License", "LGPL", "#28a745", 120),
      docLink: "/licenses/lgpl",
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
      badge: chipBadge("License", "Bitstream Vera", "#28a745", 120),
      docLink: "/licenses/bitstream",
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
      badge: chipBadge("License", "Apache 2.0", "#28a745", 120),
      docLink: "/licenses/apache",
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
      badge: chipBadge("License", "MIT", "#28a745", 120),
      docLink: "/licenses/mit",
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
      badge: chipBadge("License", "BSD", "#28a745", 120),
      docLink: "/licenses/bsd",
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
      badge: chipBadge("License", "Public Domain", "#28a745", 120),
      docLink: "/licenses/public-domain",
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
      badge: chipBadge("License", "CC0 1.0", "#28a745", 120),
      docLink: "/licenses/cc0",
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
      badge: chipBadge("License", "CC BY 4.0", "#28a745", 120),
      docLink: "/licenses/cc-by",
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
      badge: chipBadge("License", "CC BY-SA 4.0", "#28a745", 120),
      docLink: "/licenses/cc-by-sa",
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
      badge: chipBadge("License", "GPL", "#28a745", 120),
      docLink: "/licenses/gpl",
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
      badge: chipBadge("License", "IPA", "#28a745", 120),
      docLink: "/licenses/ipa",
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
        badge: chipBadge("License", "Freeware", "#007bff", 120),
        docLink: "/licenses/freeware",
        spdxUrl: null,
        category: "freely_distributable",
        isOpen: false,
        warning: "🔵 **Freeware**: Free for personal use, but redistribution may be restricted. Check the license terms.",
      };
    }

    return {
      type: "free_use",
      name: "Freely Usable",
      badge: chipBadge("License", "Free to Use", "#28a745", 120),
      docLink: "/licenses/free-use",
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
      badge: chipBadge("License", "Free to Use", "#28a745", 120),
      docLink: "/licenses/free-use",
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
      badge: chipBadge("License", "Free Commercial", "#28a745", 120),
      docLink: "/licenses/free-use",
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
      badge: chipBadge("License", "Freely Distributable", "#007bff", 120),
      docLink: "/licenses/microsoft-web",
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
      badge: chipBadge("License", "MS Software", "#8b5cf6", 120),
      docLink: "/licenses/ms-office",
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
      badge: chipBadge("License", "Adobe Software", "#8b5cf6", 120),
      docLink: "/licenses/adobe",
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
      badge: chipBadge("License", "Bundled Software", "#8b5cf6", 120),
      docLink: "/licenses/bundled",
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
    badge: chipBadge("License", "Check Source", "#17a2b8", 120),
    docLink: "/licenses/unknown",
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
  const originalYamlText = text; // Store original YAML for display

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
        formats: style.formats || [],
        variable_font: style.variable_font || false,
        variable_axes: style.variable_axes || [],
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
          formats: style.formats || [],
          variable_font: style.variable_font || false,
          variable_axes: style.variable_axes || [],
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
          formats: style.formats || [],
          variable_font: style.variable_font || false,
          variable_axes: style.variable_axes || [],
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
      const format = resource.format || null;
      const variableAxes = resource.variable_axes || [];
      if (resource.urls && resource.urls.length > 0) {
        const sizeKB = resource.file_size
          ? `${(resource.file_size / 1024).toFixed(1)} KB`
          : "Unknown";
        const shaFull = resource.sha256 && typeof resource.sha256 === "string"
          ? resource.sha256
          : null;
        const shaShort = shaFull
          ? `\`${shaFull.substring(0, 12)}...\``
          : "N/A";
        return resource.urls.map((url, index) => ({
          name: resource.urls.length > 1 ? `${name} (mirror ${index + 1})` : name,
          format,
          variableAxes,
          sizeKB,
          shaShort,
          shaFull,
          downloadUrl: url,
        }));
      }
      if (resource.files && resource.files.length > 0) {
        return resource.files.map((url) => {
          const fileName = url.split("/").pop();
          return {
            name: fileName,
            format,
            variableAxes,
            sizeKB: "Direct",
            shaShort: "N/A",
            downloadUrl: url,
          };
        });
      }
      return [];
    });

    if (resourceEntries.length > 0) {
      const hasFormat = resourceEntries.some((e) => e.format);
      const hasVariable = resourceEntries.some((e) => e.variableAxes && e.variableAxes.length > 0);
      const fmtHdr = hasFormat ? ` | Format ${v5Tag}` : "";
      const fmtSep = hasFormat ? " | ------" : "";
      const varHdr = hasVariable ? ` | Variable ${v5Tag}` : "";
      const varSep = hasVariable ? " | --------" : "";

      resourcesSection = `## Resources

| File${fmtHdr} | Size | SHA256 | Download |${varHdr}
|------${fmtSep} |------|--------|----------|${varSep}
${resourceEntries
  .map((entry) => {
    let shaCell = "N/A";
    if (entry.shaFull) {
      shaCell = `<span class="sha-cell"><code class="sha-value" title="${entry.shaFull}">${entry.shaShort}</code><button class="sha-copy-btn" data-sha="${entry.shaFull}">Copy</button></span>`;
    }
    const fmtCell = hasFormat ? ` | ${entry.format || "-"}` : "";
    const axesText = entry.variableAxes && entry.variableAxes.length > 0 ? entry.variableAxes.join(", ") : "-";
    const varCell = hasVariable ? ` | ${axesText}` : "";
    return `| <span class="font-filename" title="${entry.name}">${entry.name}</span>${fmtCell} | ${entry.sizeKB} | ${shaCell} | [Download](${entry.downloadUrl}) |${varCell}`;
  })
  .join("\n")}
`;
    }
  }

  // Build fonts section
  let fontsSection = "";
  const familyNames = Object.keys(fontFamilies);
  if (familyNames.length > 0) {
    const showFamilyIndex = familyNames.length >= 5;
    const familyIndex = showFamilyIndex
      ? `<div class="family-jump">\n${familyNames
          .map((fn) => `<a href="#${slugify(fn)}" class="family-jump-link">${fn}</a>`)
          .join(" ")}</div>\n\n`
      : "";

    fontsSection = `## Font Families

${familyIndex}${familyNames
  .map((familyName) => {
    const styles = fontFamilies[familyName];
    const uniqueTypes = [...new Set(styles.map((s) => s.type))];
    const hasFormats = styles.some((s) => s.formats && s.formats.length > 0);
    const hasVariable = styles.some((s) => s.variable_font);
    const fmtHdr = hasFormats ? ` | Formats ${v5Tag}` : "";
    const fmtSep = hasFormats ? " | ------------------" : "";
    const varHdr = hasVariable ? ` | Variable ${v5Tag}` : "";
    const varSep = hasVariable ? " | -------------------" : "";

    return `### ${familyName}

*${styles.length} ${styles.length === 1 ? "style" : "styles"}: ${uniqueTypes.join(", ")}*

<div class="font-styles-table">

| Style | Font File${fmtHdr}${varHdr} | PostScript Name | Version |
|-------|-----------${fmtSep}${varSep}|-----------------|---------|
${styles
  .map((style) => {
    const fontFile = style.font || "N/A";
    const psName = style.post_script_name || "N/A";
    const version = style.version
      ? style.version.split(";")[0].trim()
      : "N/A";
    const fmtCell = hasFormats ? ` | ${(style.formats || []).join(", ") || "-"}` : "";
    const varCell = hasVariable
      ? ` | ${style.variable_font ? `Yes (${(style.variable_axes || []).join(", ")})` : "No"}`
      : "";
    return `| ${style.type} | <span class="font-filename" title="${fontFile}">${fontFile}</span>${fmtCell}${varCell} | ${psName} | ${version} |`;
  })
  .join("\n")}

</div>`;
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

  // Get the real license text (prefer open_license, fallback to requires_license_agreement)
  const realLicenseText = yaml.open_license || yaml.requires_license_agreement || "";
  const licenseTextSection = realLicenseText ? `

<details>
<summary>View Full License Text</summary>

\`\`\`
${realLicenseText}
\`\`\`

</details>
` : "";

  let licenseSection = `## License

${licenseInfo.badge}

**${licenseInfo.name}**${licenseLinksText}

${licenseInfo.warning || ""}${licenseTextSection}${
  yaml.license_url
    ? `\nLicense URL: [${yaml.license_url}](${yaml.license_url})`
    : ""
}
`;

  // Build copyright section
  let copyrightSection = "";
  if (allCopyrights.size > 0) {
    copyrightSection = `## Copyright

${[...allCopyrights]
  .map((c) => `- ${escapeBareUrls(c.replace(/</g, "&lt;").replace(/>/g, "&gt;"))}`)
  .join("\n")}
`;
  }

  // Build install command - use full slug for --formula flag
  const installCmd = `fontist install --formula "${slug}"`;

  // Generate meta description
  const styleCount = allStyles.length;
  const familyCount = familyNames.length;
  const metaDescription = `${displayName} font package for Fontist. ${familyCount} font families, ${styleCount} styles. Install: fontist install "${formulaName}"`;

  // Build hero eyebrow chips
  const heroChips = [licenseInfo.badge, sourceInfo.chip];
  if (yaml.homepage) {
    const homepageLabel = yaml.homepage.replace(/^https?:\/\//, "").replace(/\/$/, "");
    heroChips.push(`<a href="${yaml.homepage}" class="detail-chip detail-chip--link"><span class="detail-chip-k">Web</span><span class="detail-chip-v">${homepageLabel}</span></a>`);
  }

  // Build source line (below install)
  let importSourceText = "";
  if (yaml.import_source && Object.keys(yaml.import_source).length > 0) {
    const is = yaml.import_source;
    const details = [];
    if (is.type) details.push(`type: ${is.type}`);
    if (is.version) details.push(`version: ${is.version}`);
    if (is.commit_id) details.push(`commit: ${String(is.commit_id).slice(0, 8)}`);
    if (is.release_date) details.push(`date: ${is.release_date}`);
    if (is.framework_version) details.push(`framework: ${is.framework_version}`);
    if (is.asset_id) details.push(`asset: ${is.asset_id}`);
    if (is.family_id) details.push(`family: ${is.family_id}`);
    importSourceText = ` · <span class="import-meta">Import Source ${v5Tag}: ${details.join(" · ")}</span>`;
  }

  const heroDesc = yaml.description && yaml.description !== displayName
    ? `<p class="hero-desc">${escapeBareUrls(yaml.description)}</p>`
    : "";

  // Build complete markdown
  const md = `\
---
title: "${displayName} - Fontist Formula"
description: "${escapeYAMLString(metaDescription)}"
outline: [2, 3]
---

<div class="formula-hero">
<div class="hero-eyebrow">${heroChips.join(" ")}</div>
<h1 class="hero-title">${displayName}</h1>${heroDesc ? "\n" + heroDesc : ""}
</div>

## Install

\`\`\`bash
${installCmd}
\`\`\`

<div class="source-line">

<a href="${githubURL}" class="source-link">Formula YAML ↗</a>${importSourceText}

</div>

${resourcesSection}
${fontsSection}
${copyrightSection}
${licenseSection}

## Formula Source

- [View YAML on GitHub](${githubURL})

<ShaCopy />
`;

  await mkdir(dirname(`browse/${slug}.md`), { recursive: true });
  await writeFile(`browse/${slug}.md`, md);

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

// Lightweight stats for the homepage counters.
// Lets the landing page render totals without fetching the full 1.8MB index.
// See https://github.com/fontist/formulas/issues/245
const stats = {
  total: allFormulas.length,
  licenses: {
    open_source: 0,
    freely_distributable: 0,
    platform_restricted: 0,
    bundled_software: 0,
  },
  sources: {
    google: 0,
    sil: 0,
    macos: 0,
    manual: 0,
  },
};
allFormulas.forEach((f) => {
  const lic = f.licenseCategory || "unknown";
  if (stats.licenses[lic] !== undefined) stats.licenses[lic]++;
  const src = f.sourceType || "unknown";
  if (stats.sources[src] !== undefined) stats.sources[src]++;
});
await writeFile("public/stats.json", JSON.stringify(stats, null, 2));

// Slim search index for the homepage autocomplete dropdown.
// Lazy-loaded only when the user focuses the search input.
// Drops licenseName, platforms, styleCount and other fields the homepage
// never reads, cutting payload substantially versus formulas-data.json.
const searchIndex = allFormulas.map((f) => ({
  name: f.name,
  formulaName: f.formulaName,
  slug: f.slug,
  familyNames: f.familyNames,
  licenseType: f.licenseType,
  licenseCategory: f.licenseCategory,
  sourceType: f.sourceType,
  familyCount: f.familyCount,
}));
await writeFile("public/search-index.json", JSON.stringify(searchIndex, null, 2));

// Generate Vue-based interactive index page
const indexMd = `\
---
search: false
outline: false
---

# All Formulas

<FormulaBrowser />
`;

await writeFile(`browse/index.md`, indexMd);

console.log(`Generated ${allFormulas.length} formula pages`);

// Generate license pages from YAML data
const { generateLicenses } = await import("./licenses/generate-licenses.js");
await generateLicenses();
