# Fontist Formulas Guide

This guide explains font concepts, Fontist concepts, and how to use Fontist formulas to install and manage fonts.

## Font Concepts

### What is a Font?

A **font** is a set of typographic characters (glyphs) with a consistent design. Fonts define how text appears visually—its style, weight, and character shapes.

### What is a Font Family?

A **font family** is a collection of related fonts that share a common design but vary in specific attributes:

- **Weight**: Thin, Light, Regular, Medium, Bold, Black, etc.
- **Width**: Condensed, Normal, Extended
- **Slope**: Upright (Roman), Italic, Oblique

Example: "Roboto" is a font family containing Roboto Thin, Roboto Light, Roboto Regular, Roboto Bold, Roboto Italic, etc.

### What is a Font Style?

A **font style** refers to a specific variant within a font family, defined by its combination of weight, width, and slope. For example:

- "Bold Italic" is a style combining bold weight with italic slope
- "Condensed Light" is a style combining condensed width with light weight

### What are Glyphs?

**Glyphs** are the individual characters, symbols, or shapes within a font. Each glyph represents a specific character (like 'A', 'あ', 'α') or symbol (like '→', '©', '€').

A font's **glyph coverage** or **character set** determines which writing systems it supports:

- **Latin**: Basic Western European characters
- **Latin Extended**: Additional European characters
- **Cyrillic**: Russian, Ukrainian, Bulgarian, etc.
- **Greek**: Modern and ancient Greek
- **CJK**: Chinese, Japanese, Korean characters
- **Arabic**: Arabic script languages
- **And more**: Thai, Hebrew, Devanagari, etc.

### What is a Foundry?

A **foundry** is a company or organization that designs and distributes fonts. Examples include:

- **Google Fonts** - Open source web fonts
- **Adobe** - Professional typefaces
- **Monotype** - Classic and commercial fonts
- **SIL International** - Linguistic and scholarly fonts

### Font Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **TTF** (TrueType) | Standard outline font format | Desktop applications, web |
| **OTF** (OpenType) | Advanced features, cross-platform | Desktop publishing, professional use |
| **WOFF** | Web Open Font Format | Web embedding |
| **WOFF2** | Compressed WOFF | Web embedding (smaller files) |
| **EOT** | Embedded OpenType | Legacy Internet Explorer |
| **TTC** (TrueType Collection) | Multiple fonts in one file | System fonts (e.g., macOS) |

### Font Versions

Fonts have **version numbers** that indicate releases. Version changes may include:

- Bug fixes (hinting, spacing issues)
- New glyphs or character support
- Design refinements
- Technical improvements

Always note which version you're using when reporting issues.

### Font Licenses

Font licenses define how you can use, modify, and distribute fonts. Key license types:

#### Open Source Licenses

| License | Redistribution | Modification | Commercial Use | Notes |
|---------|---------------|--------------|----------------|-------|
| **OFL 1.1** (SIL Open Font License) | ✅ Yes | ✅ Yes | ✅ Yes | Most common for open fonts |
| **Apache 2.0** | ✅ Yes | ✅ Yes | ✅ Yes | Google Material Icons |
| **MIT** | ✅ Yes | ✅ Yes | ✅ Yes | Permissive |
| **CC0** (Public Domain) | ✅ Yes | ✅ Yes | ✅ Yes | No restrictions |
| **UFL** (Ubuntu Font License) | ✅ Yes | ✅ Yes | ✅ Yes | Similar to OFL |
| **GUST** | ✅ Yes | ✅ Yes | ✅ Yes | TeX fonts |

#### Restricted Licenses

| Type | Desktop Use | Web Use | Modification | Notes |
|------|-------------|---------|--------------|-------|
| **Freeware** | ✅ Yes | ✅ Yes | ❌ No | Free but may restrict redistribution |
| **Platform Fonts** | ⚠️ Limited | ⚠️ Limited | ❌ No | macOS, Windows system fonts |
| **Commercial** | 💰 License | 💰 License | 💰 License | Requires purchase |

#### License Permissions to Check

When using fonts, verify these permissions:

1. **Redistribution**: Can you include the font in your project?
2. **Web Use (WOFF/WOFF2)**: Can you convert and serve on websites?
3. **Desktop Use**: Can you install on local machines?
4. **Server/CI Use**: Can you install on build servers or cloud CI?
5. **Modification**: Can you modify the font files?
6. **Subsetting**: Can you create partial font subsets?
7. **Commercial Use**: Can you use in commercial projects?
8. **Embedding**: Can you embed in PDFs, apps, or documents?

---

## Fontist Concepts

### What is a Formula?

A **formula** is a YAML file that tells Fontist how to download, extract, and install a font package. Formulas are similar to Homebrew formulas but for fonts.

Each formula contains:

```yaml
name: "Font Name"
description: "Font description"
homepage: "https://example.com/font"
license_url: "https://example.com/license"
resources:
  font.zip:
    urls:
      - https://example.com/download/font.zip
    sha256: "abc123..."
fonts:
  - name: "Font Family"
    styles:
      - family_name: "Font Family"
        type: "Regular"
        font: "Font-Regular.ttf"
        post_script_name: "Font-Regular"
        version: "1.0"
```

### What is a Font Manifest?

A **manifest** is Fontist's internal index that maps font names and styles to their installation locations. When you run `fontist install`, Fontist:

1. Reads the formula
2. Downloads the font files
3. Installs them to your Fontist directory
4. Updates the manifest with the installed fonts

The manifest enables quick font lookups without re-scanning all files.

### Formula vs Manifest

| Aspect | Formula | Manifest |
|--------|---------|----------|
| Purpose | Installation instructions | Installation record |
| Location | `Formulas/` directory | `~/.fontist/index.yml` |
| Created by | Fontist maintainers | Auto-generated by Fontist |
| Contains | Download URLs, SHA256, metadata | Installed font paths |

### The Fontist Directory

Fontist stores fonts in a central directory:

```
~/.fontist/
├── fonts/           # Installed font files
├── formulas/        # Downloaded formula files
└── index.yml        # Font manifest
```

---

## Using Fontist

### Installing a Font

```bash
# Install by formula name
fontist install "open_sans"

# Install by font name (Fontist will find the right formula)
fontist install "Open Sans"

# Install specific styles
fontist install "open_sans" --style "Bold"
```

### Locating Installed Fonts

After installation, find fonts using:

```bash
# Show Fontist directory location
fontist config

# List all installed fonts
fontist list

# Find where a specific font is installed
fontist status "Open Sans"
```

Default installation location:

```
~/.fontist/fonts/
```

### Checking Font Locations Programmatically

In scripts, use:

```bash
# Get font path
fontist font-path "Open Sans" "Regular"

# Get all paths for a font family
fontist font-path "Open Sans"
```

---

## GitHub Actions Integration

Use Fontist in CI/CD pipelines with the official GitHub Action:

```yaml
- name: Install fonts
  uses: fontist/setup-fontist@v1
  with:
    fonts: Open Sans, Roboto
```

Or manually:

```yaml
- name: Install Fontist
  run: gem install fontist

- name: Install fonts
  run: |
    fontist install "Open Sans"
    fontist install "Roboto"
```

### Common CI Use Cases

1. **Document Generation**: Install fonts for PDF generation
2. **Screenshot Testing**: Ensure consistent font rendering
3. **Design Automation**: Use specific fonts in automated designs
4. **Report Generation**: Create reports with corporate fonts

---

## Formula Sources

### Google Fonts

Google Fonts formulas are automatically generated from the Google Fonts repository. They use the SIL Open Font License (OFL 1.1).

- **Count**: 1600+ fonts
- **License**: OFL 1.1
- **Auto-updated**: Daily via CI

### SIL International

Fonts from SIL International, primarily for linguistic and scholarly use.

- **License**: OFL 1.1
- **Website**: https://scripts.sil.org/

### Expert Curated

Curated formulas from various sources:

- **System fonts**: Extracted from OS distributions
- **Foundry fonts**: Direct from type designers
- **Web fonts**: Converted from web sources

---

## Troubleshooting

### Font Not Found

If `fontist install` can't find a font:

1. Check the spelling (use `fontist search "name"`)
2. The font may not have a formula yet
3. Create a request on GitHub

### Installation Fails

Common causes:

1. **Network issues**: Check your internet connection
2. **SHA256 mismatch**: Formula may be outdated
3. **Permission denied**: Check write permissions for `~/.fontist/`

### Font Not Showing in Applications

1. Run `fontist status` to verify installation
2. Some apps require restart to detect new fonts
3. Check if the app uses system fonts or Fontist fonts

---

## Contributing

### Adding a New Formula

Use the `create-formula` command:

```bash
fontist create-formula https://example.com/font.zip
```

This generates a formula file with:
- SHA256 checksums
- Font metadata extraction
- Proper structure

### Reporting Issues

Report formula issues at:
https://github.com/fontist/formulas/issues

Include:
- Formula name
- Error message
- Your OS and Ruby version
