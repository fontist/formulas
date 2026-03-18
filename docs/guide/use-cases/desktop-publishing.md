---
title: Desktop Publishing
description: Using Fontist formulas for desktop publishing applications
---

# Desktop Publishing

Fontist integrates seamlessly with desktop publishing applications like Adobe InDesign, Scribus, and Adobe Illustrator.

## Installation

### Install Fonts for Desktop Use

```bash
# Install a font for desktop use
fontist install "open_sans"

# Install multiple fonts
fontist install "roboto" "lato" "source_sans"
```

### Verify Installation

```bash
# Check installed fonts
fontist list

# Find specific font location
fontist status "Open Sans"
```

## Application Integration

### Adobe InDesign

1. **Install fonts** using Fontist
2. **Restart InDesign** to detect new fonts
3. **Use fonts** in your documents

::: tip
Fontist installs fonts to `~/.fontist/fonts/` by default. Some applications may need to be configured to use this directory.
:::

### Scribus

Scribus automatically detects fonts installed in user directories:

```bash
# Install Scribus-compatible fonts
fontist install "liberation" "dejavu"
```

### Adobe Illustrator

Same as InDesign - install fonts and restart the application.

## License Considerations

For desktop publishing, pay attention to:

| Use Case | License Required | Notes |
|----------|-----------------|-------|
| Print documents | Most licenses allow | Check "Commercial (Static)" permission |
| PDF export | Most licenses allow | Embedding may have conditions |
| Client work | Check license | Some restrict commercial work |
| Font modification | Rarely allowed | OFL requires renaming |

### Recommended Licenses for Desktop Publishing

- **OFL 1.1** - Best choice, allows all desktop uses
- **Apache 2.0** - Fully permissive
- **MIT** - Fully permissive

## Troubleshooting

### Fonts Not Showing in Application

1. Restart the application
2. Check font installation: `fontist status "Font Name"`
3. Some apps need system font cache refresh

### Font Subsetting in PDFs

Most licenses allow subsetting when embedding in PDFs. OFL 1.1 explicitly permits this.

## See Also

- [Choosing a Formula](/guide/choosing-formula)
- [License Overview](/licenses/)
