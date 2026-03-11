---
title: Choosing a Formula
description: How to choose the right Fontist formula for your needs
---

# Choosing a Formula

With hundreds of formulas available, choosing the right one can be challenging. This guide helps you find the perfect formula for your use case.

## By Use Case

### Desktop Publishing

For print design, desktop publishing, or local document creation:

| Need | Recommended Formulas | Why |
|------|---------------------|-----|
| Professional typography | `tex_gyre`, `dejavu`, `liberation` | High quality, comprehensive character sets |
| Open source | `google/*` formulas | OFL licensed, free to use |
| Specific styles | Check formula for available weights | Look for "styles" section |

### Web Development

For self-hosted web fonts:

| Need | Recommended Formulas | Why |
|------|---------------------|-----|
| WOFF/WOFF2 conversion | OFL-licensed formulas | Allow format conversion |
| Subsetting | OFL, Apache, MIT licenses | Permit subsetting |
| CDN hosting | Check license allows "Web (Hosting)" | Not all licenses allow this |

### Document Generation (CI/CD)

For automated document generation in pipelines:

| Need | Recommended Formulas | Why |
|------|---------------------|-----|
| Reproducible builds | Open source formulas | Stable, well-defined licenses |
| GitHub Actions | Any formula with clear license | Install via `fontist/setup-fontist` action |
| Docker containers | Open source, freely distributable | Include in container images |

## By License Type

### Open Source (Recommended)

::: tip Best for most use cases
Open source licenses provide the most flexibility for all use cases.
:::

| License | Formulas | Use Cases |
|---------|----------|-----------|
| OFL 1.1 | `google/*`, `sil/*` | Any use case |
| Apache 2.0 | Material fonts | Any use case |
| MIT | Various | Any use case |

### Platform Restricted

::: warning License compliance required
These fonts are only legal on specific platforms.
:::

| License | Platform | Cloud Options |
|---------|----------|---------------|
| Apple-only | macOS | GitHub Actions (macOS), MacStadium |
| Microsoft Software | Windows | Azure, Windows containers |

### Bundled Software

These fonts require the parent software to be installed:

| License | Requires | Usage Rights |
|---------|----------|--------------|
| Adobe Software | Adobe product installed | Use anywhere on that machine |
| Microsoft Office | MS Office installed | Use anywhere on that machine |

## Search Tips

### Search by Font Name

```bash
fontist search "Open Sans"
```

### Search by Style

```bash
fontist search "Bold"
```

### Browse All

```bash
fontist list
```

## Common Scenarios

### "I need a font for PDF generation"

1. Check if you need specific branding/fonts
2. If not, use OFL-licensed fonts like `google/roboto`, `google/opensans`
3. Install: `fontist install "google/roboto"`

### "I need to use macOS fonts in CI"

1. Use GitHub Actions with `macos-latest` runner
2. Fonts are pre-installed on macOS runners
3. Or install via Fontist formula for reproducibility

### "I need Microsoft fonts"

**Option A: Microsoft Web Fonts (Freely Distributable)**
- Core fonts like Arial, Times New Roman, Verdana
- Install: `fontist install "andale"`
- License allows redistribution

**Option B: Microsoft Office Fonts**
- Requires Microsoft Office license
- Install on Windows machines/VMs

## Decision Matrix

| Your Need | License Priority | Platform |
|-----------|-----------------|----------|
| Any use, maximum freedom | OFL, Apache, MIT | Any |
| Need specific font, flexible use | Check license | Any |
| Need specific font, restricted license | Check platform | macOS/Windows |
| Commercial product bundling | OFL, Apache, MIT | Any |
| Server-side rendering | OFL, Apache, MIT, Free | Any |

## Getting Help

If you're still unsure:

1. Check the formula page for license details
2. Visit the font's homepage (linked in formula)
3. Ask on [GitHub Discussions](https://github.com/fontist/formulas/discussions)
