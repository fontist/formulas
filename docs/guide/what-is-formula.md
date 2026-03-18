---
title: What is a Formula?
description: Understanding Fontist formulas - recipes for installing fonts
---

# What is a Formula?

A **Fontist Formula** is a YAML file that describes how to download, install, and manage a font package. Think of it as a recipe for fonts - it tells Fontist where to find the fonts, how to verify them, and what fonts are included.

## Key Concepts

### Formula = Installation Recipe

Just like a package manager has packages, Fontist has formulas. Each formula contains:

- **Where** to download fonts from
- **How** to verify downloads (SHA256 checksums)
- **What** fonts are included (family names, styles, file names)
- **License** information

### Formula vs Font

| Concept | Description |
|---------|-------------|
| Formula | The installation instructions (YAML file) |
| Font | The actual font files (TTF, OTF, WOFF, etc.) |
| Font Family | A group of related fonts (Regular, Bold, Italic, etc.) |

## What's in a Formula?

```yaml
name: "Open Sans"              # Display name
description: "Sans-serif font" # Brief description
homepage: "https://..."        # Font homepage

resources:                     # Download sources
  font.zip:
    urls:
      - https://example.com/font.zip
    sha256: "abc123..."       # Verification checksum

fonts:                         # Included fonts
  - name: "Open Sans"
    styles:
      - type: "Regular"
        font: "OpenSans-Regular.ttf"
```

## Why Formulas?

### Reproducible Installations

Formulas ensure the same fonts are installed identically across:
- Different machines
- CI/CD pipelines
- Docker containers
- Cloud VMs

### Verification

Every download is verified with SHA256 checksums, ensuring:
- Files haven't been tampered with
- Downloads are complete and correct
- Reproducible installations

### License Awareness

Formulas include license information so you can:
- Check if a font allows your use case
- Understand redistribution rights
- Make informed decisions

## Finding Formulas

### Browse Online

Visit the [Formulas Index](/formulas/) to search and browse all available formulas.

### Search via CLI

```bash
fontist search "open sans"
```

### List All

```bash
fontist list
```

## Formula Sources

Formulas come from various sources:

| Source | Prefix | Description |
|--------|--------|-------------|
| Google Fonts | `google/` | 1600+ open source fonts |
| SIL International | `sil/` | Linguistic fonts |
| macOS System | `macos/` | Apple system fonts |
| Expert Curated | (none) | Curated formulas |

## Installing from a Formula

```bash
# Install by formula name
fontist install "open_sans"

# Install by font name (Fontist finds the formula)
fontist install "Open Sans"

# Install specific styles
fontist install "open_sans" --style "Bold"
```

## See Also

- [Formula Structure](/guide/formula-structure) - Detailed YAML structure
- [Choosing a Formula](/guide/choosing-formula) - How to pick the right one
- [Create a Formula](/guide/create-formula) - Make your own formula
