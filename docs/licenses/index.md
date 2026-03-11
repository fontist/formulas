# Font License Guide

This guide explains font licenses, their permissions, and how to determine what you can do with a font.

## Quick Reference

| Category | Icon | Description |
|----------|------|-------------|
| Open Source | 🟢 | Fully open licenses (OFL, Apache, MIT, etc.) |
| Freely Distributable | 🔵 | Free to redistribute with conditions |
| Platform Restricted | 🟡 | Limited to specific platforms (macOS, Windows) |
| Bundled Software | 🟣 | Comes with specific software |
| Unknown | ❓ | License not specified in formula |

## License Categories

### 🟢 Open Source Fonts

Fonts licensed under open source licenses that generally allow:

- ✅ Free use (personal and commercial)
- ✅ Redistribution
- ✅ Modification
- ✅ Web embedding
- ✅ Subsetting

**Available Licenses:**

| License | Identifier | SPDX |
|---------|------------|------|
| [SIL Open Font License 1.1](./ofl) | OFL 1.1 | [OFL-1.1](https://spdx.org/licenses/OFL-1.1.html) |
| [Apache License 2.0](./apache) | Apache 2.0 | [Apache-2.0](https://spdx.org/licenses/Apache-2.0.html) |
| [MIT License](./mit) | MIT | [MIT](https://spdx.org/licenses/MIT.html) |
| [BSD License](./bsd) | BSD | [BSD-3-Clause](https://spdx.org/licenses/BSD-3-Clause.html) |
| [CC0 / Public Domain](./cc0) | CC0 1.0 | [CC0-1.0](https://spdx.org/licenses/CC0-1.0.html) |
| [Public Domain](./public-domain) | Public Domain | Not on SPDX |
| [CC-BY 4.0](./cc-by) | CC BY 4.0 | [CC-BY-4.0](https://spdx.org/licenses/CC-BY-4.0.html) |
| [CC-BY-SA 4.0](./cc-by-sa) | CC BY-SA 4.0 | [CC-BY-SA-4.0](https://spdx.org/licenses/CC-BY-SA-4.0.html) |
| [Ubuntu Font License 1.0](./ufl) | UFL 1.0 | [Ubuntu-font-1.0](https://spdx.org/licenses/Ubuntu-font-1.0.html) |
| [GUST Font License](./gust) | GUST | Not on SPDX |
| [GNU LGPL](./lgpl) | LGPL | [LGPL-3.0](https://spdx.org/licenses/LGPL-3.0.html) |
| [GNU GPL (Font Exception)](./gpl) | GPL | [GPL-3.0](https://spdx.org/licenses/GPL-3.0.html) |
| [IPA Font License](./ipa) | IPA | [IPA](https://spdx.org/licenses/IPA.html) |
| [Bitstream Vera License](./bitstream) | Bitstream | [Bitstream-Vera](https://spdx.org/licenses/Bitstream-Vera.html) |
| [Freely Usable](./free-use) | Free to Use | Not on SPDX |

### 🔵 Freely Distributable

Fonts that can be redistributed under specific terms:

| License | Description |
|---------|-------------|
| [Microsoft Web Fonts EULA](./microsoft-web) | Unlimited redistribution (not for profit) |
| [Freeware](./freeware) | Free for personal use, redistribution restricted |

### 🟡 Platform Restricted

Fonts that come with specific platforms:

| License | Description |
|---------|-------------|
| [Apple-only](./apple-only) | Licensed for use on Apple-branded systems only |

### 🟣 Bundled Software

Fonts that come with specific software:

| License | Description |
|---------|-------------|
| [Microsoft Software License](./ms-office) | Bundled with MS Office/Windows |
| [Adobe Software License](./adobe) | Bundled with Adobe products |
| [Software Bundle License](./bundled) | Bundled with other software |

### ❓ Unknown

| License | Description |
|---------|-------------|
| [License Not Specified](./unknown) | No license info in formula |

---

## Usage Contexts

Different licenses permit or restrict different usage contexts:

| Context | Description |
|---------|-------------|
| **Academic** | Use in educational institutions, research, thesis |
| **Non-commercial** | Personal projects, hobby use |
| **Commercial (Static)** | Creating static artifacts like PDFs, images for sale |
| **Commercial (Server)** | Dynamic artifact generation on servers |
| **Web (Hosting)** | Self-hosting WOFF/WOFF2/SVG fonts |
| **Web (Subsetting)** | Subsetting for web performance |
| **Modification** | Editing glyphs, customization |
| **Redistribution** | Distributing font files (standalone or bundled) |
| **Format Conversion** | Converting TTF ↔ WOFF ↔ WOFF2 |

---

## How to Determine Font License

### Step 1: Check the Formula

Each formula page shows:
- License badge (if detected)
- License URL (if provided)
- Copyright notice
- Any license agreement text

### Step 2: Visit the Homepage

The formula includes a homepage link. Visit it to find:
- Official license information
- Usage terms
- Contact information

### Step 3: Check the Font Files

Font files often contain license metadata:

```bash
# Using otfinfo (install via lcdf-typetools)
otfinfo --info Font.ttf | grep -i license

# Using fonttools
ttx -t name Font.ttf | grep -i license
```

### Step 4: Contact the Foundry

If unclear, contact the font creator:
- Foundry website
- Email from formula homepage
- GitHub repository (if available)

---

## Reporting License Issues

If you find incorrect license information:

1. Open an issue on GitHub: https://github.com/fontist/formulas/issues
2. Include the formula name
3. Provide correct license information with source

We take license accuracy seriously.
