---
title: Web Development
description: Using Fontist formulas for web development and self-hosted web fonts
---

# Web Development

Fontist helps you download and manage fonts for self-hosted web applications.

## Self-Hosting Web Fonts

### Download Fonts

```bash
# Install fonts for web use
fontist install "roboto"
```

### Convert to Web Formats

Most fonts can be converted to WOFF/WOFF2:

```bash
# Using fonttools
pip install fonttools brotli
pyftsubset Roboto-Regular.ttf \
  --output-file=Roboto-Regular.woff2 \
  --flavor=woff2
```

### CSS @font-face

```css
@font-face {
  font-family: 'Roboto';
  src: url('/fonts/Roboto-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
}
```

## License Considerations

| Use Case | Permission to Check |
|----------|-------------------|
| Self-hosting | "Web (Hosting)" |
| WOFF/WOFF2 conversion | "Format Conversion" |
| Subsetting | "Web (Subsetting)" |
| CDN delivery | Check redistribution terms |

### Best Licenses for Web

- **OFL 1.1** - Allows all web uses
- **Apache 2.0** - Fully permissive
- **CC0** - Public domain, no restrictions

### Restricted Licenses

- **Platform Restricted** (Apple-only) - Cannot use on web servers
- **Bundled Software** - Cannot extract for web use

## Subsetting for Performance

```bash
# Create Latin-only subset
pyftsubset Roboto-Regular.ttf \
  --output-file=Roboto-Regular-latin.woff2 \
  --flavor=woff2 \
  --subset-latin \
  --layout-features='*'
```

## Google Fonts Alternative

For web use, you can also use Google Fonts CDN:

```html
<link href="https://fonts.googleapis.com/css2?family=Roboto&display=swap" rel="stylesheet">
```

Use Fontist when you need to:
- Self-host for privacy/performance
- Use fonts not on Google Fonts
- Ensure reproducible builds

## See Also

- [Choosing a Formula](/guide/choosing-formula)
- [OFL License](/licenses/ofl)
