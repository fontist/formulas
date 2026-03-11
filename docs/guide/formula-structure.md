---
title: Formula Structure
description: Understanding the YAML structure of Fontist formulas
---

# Formula Structure

A Fontist formula is a YAML file that describes how to download, extract, and install a font package. Understanding the structure helps you choose the right formula and troubleshoot issues.

## Basic Structure

```yaml
---
name: "Font Name"
description: "Brief description of the font"
homepage: "https://example.com/font"
license_url: "https://example.com/license"

resources:
  font-archive.zip:
    urls:
      - https://example.com/download/font.zip
    sha256: "abc123..."
    file_size: 123456

fonts:
  - name: "Font Family"
    styles:
      - family_name: "Font Family"
        type: "Regular"
        full_name: "Font Family Regular"
        post_script_name: "FontFamily-Regular"
        version: "1.0"
        font: "Font-Regular.ttf"
        copyright: "Copyright holder"
```

## Key Fields

### Metadata Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name of the font package |
| `description` | No | Brief description |
| `homepage` | No | URL to font homepage |
| `license_url` | No | URL to license information |
| `copyright` | No | Copyright notice |
| `license` | No | License identifier |

### Resources Section

The `resources` section defines where to download font files:

```yaml
resources:
  filename.zip:
    urls:           # List of download URLs (mirrors)
      - https://url1/font.zip
      - https://url2/font.zip
    sha256: "..."    # SHA256 checksum for verification
    file_size: 12345 # File size in bytes
```

### Fonts Section

The `fonts` section lists all font families and their styles:

```yaml
fonts:
  - name: "Family Name"
    styles:
      - family_name: "Family Name"
        type: "Regular"           # Style: Regular, Bold, Italic, etc.
        full_name: "Family Name Regular"
        post_script_name: "FamilyName-Regular"
        version: "1.0"
        font: "filename.ttf"      # Actual font file name
        copyright: "..."
```

### Font Collections (TTC)

For TrueType Collection files containing multiple fonts:

```yaml
font_collections:
  - filename: "fonts.ttc"
    fonts:
      - name: "Font One"
        styles:
          - family_name: "Font One"
            type: "Regular"
            font: "FontOne-Regular"
      - name: "Font Two"
        styles:
          - family_name: "Font Two"
            type: "Regular"
            font: "FontTwo-Regular"
```

## License Information

### Open License

For fonts with open source licenses:

```yaml
open_license: |
  Full license text here...
  SIL Open Font License 1.1
  ...
```

### Requires License Agreement

For fonts that require accepting a EULA:

```yaml
requires_license_agreement: |
  END-USER LICENSE AGREEMENT
  By using this software...
```

## Platform-Specific Formulas

Some formulas are platform-specific:

```yaml
# macOS system fonts
platforms:
  - macos

# Windows system fonts
platforms:
  - windows
```

## Extract Options

For archives that need special extraction:

```yaml
extract:
  format: cab        # For CAB files (Windows)
  format: zip        # For ZIP files
  format: gzip       # For GZIP files
```

## Example: Complete Formula

```yaml
---
name: "Open Sans"
description: "Open Sans is a humanist sans-serif typeface"
homepage: "https://fonts.google.com/specimen/Open+Sans"
license_url: "https://scripts.sil.org/OFL"

resources:
  open_sans.zip:
    urls:
      - https://github.com/googlefonts/OpenSans/archive/refs/tags/v1.0.zip
    sha256: "abc123def456..."
    file_size: 1234567

fonts:
  - name: "Open Sans"
    styles:
      - family_name: "Open Sans"
        type: "Regular"
        full_name: "Open Sans Regular"
        post_script_name: "OpenSans-Regular"
        version: "1.0"
        font: "OpenSans-Regular.ttf"
        copyright: "Google LLC"
  - name: "Open Sans"
    styles:
      - family_name: "Open Sans"
        type: "Bold"
        full_name: "Open Sans Bold"
        post_script_name: "OpenSans-Bold"
        version: "1.0"
        font: "OpenSans-Bold.ttf"
        copyright: "Google LLC"

open_license: |
  Copyright 2020 The Open Sans Project Authors

  This Font Software is licensed under the SIL Open Font License, Version 1.1.
  ...
```

## See Also

- [What is a Formula?](/guide/what-is-formula)
- [Choosing a Formula](/guide/choosing-formula)
- [Create a Formula](/guide/create-formula)
